import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../hydration/data/hydration_repository.dart';

/// One engine and database per account. No network await inside a SQLite transaction.
class SyncEngine extends ChangeNotifier {
  SyncEngine(this.repository, this.client, this.owner);
  final HydrationRepository repository;
  final SupabaseClient? client;
  final String owner;
  AppDatabase get db => repository.db;
  Timer? timer, debounce;
  StreamSubscription<List<SyncOutboxData>>? subscription;
  bool busy = false, stopped = false;
  String? error;
  int pending = 0, conflicts = 0;
  DateTime? lastSync;
  Future<void>? _running;
  bool get authenticated => client != null && owner != 'local-device';
  bool get valid => !stopped && client?.auth.currentUser?.id == owner;
  void changed() {
    if (!stopped) notifyListeners();
  }

  Future<void> start() async {
    if (stopped) return;
    try {
      await repository.initialize();
    } catch (_) {
      error = 'Chưa mở được dữ liệu để đồng bộ. Hãy mở lại app.';
      changed();
      return;
    }
    if (stopped || !authenticated) return;
    final saved = await metadata('last-sync');
    lastSync = saved == null ? null : DateTime.tryParse(saved);
    subscription =
        (db.select(
          db.syncOutbox,
        )..where((t) => t.ownerId.equals(owner))).watch().listen((rows) {
          pending = rows.length;
          changed();
          if (!busy && pending > 0) {
            debounce?.cancel();
            debounce = Timer(
              const Duration(milliseconds: 600),
              () => unawaited(sync()),
            );
          }
        });
    timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(sync()),
    );
    await sync();
  }

  Future<String?> metadata(String key) async => (await (db.select(
    db.syncMetadata,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;
  Future<void> put(String key, String value) => db
      .into(db.syncMetadata)
      .insertOnConflictUpdate(
        SyncMetadataCompanion.insert(key: key, value: value),
      );
  String entityKey(String operation, String id) =>
      '${operation.split('.').first}:$id';
  Future<List<SyncOutboxData>> queue() =>
      (db.select(db.syncOutbox)
            ..where((t) => t.ownerId.equals(owner))
            ..orderBy([
              // Device clocks can move backwards; preserve SQLite enqueue order.
              (t) => OrderingTerm.asc(t.rowId),
            ]))
          .get();

  Future<void> sync() {
    if (_running != null) return _running!;
    if (!authenticated || !valid) return Future.value();
    final work = _sync();
    _running = work;
    return work.whenComplete(() => _running = null);
  }

  Future<void> _sync() async {
    busy = true;
    error = null;
    changed();
    try {
      await pull();
      // A bound prevents continuous local writes from starving remote downloads.
      for (var n = 0; n < 500 && valid; n++) {
        final rows = await queue();
        if (rows.isEmpty) break;
        await push(rows.first);
      }
      if (!valid) return;
      await pull();
      if (!valid) return;
      await repository.replanAfterSync();
      lastSync = DateTime.now();
      await put('last-sync', lastSync!.toUtc().toIso8601String());
    } catch (_) {
      if (!stopped) error = 'Chưa đồng bộ được. Dữ liệu vẫn lưu trên máy và sẽ thử lại khi có mạng.';
    } finally {
      busy = false;
      changed();
    }
  }

  Future<void> push(SyncOutboxData command) async {
    final key = entityKey(command.operation, command.entityId);
    final requestKey = 'command:${command.operationId}';
    final saved = await metadata(requestKey);
    // Freeze the expected revision BEFORE HTTP. A lost response must replay exactly.
    final request = saved == null
        ? <String, dynamic>{
            'p_command_id': command.operationId,
            'p_operation': command.operation,
            'p_payload': jsonDecode(command.payload),
            'p_expected_revision': int.tryParse(
              await metadata('revision:$key') ?? '',
            ),
          }
        : Map<String, dynamic>.from(jsonDecode(saved) as Map);
    if (saved == null) await put(requestKey, jsonEncode(request));
    if (!valid) return;
    try {
      final result = await client!
          .rpc(
            command.operation.startsWith('intake.')
                ? 'apply_intake_command'
                : 'apply_settings_command',
            params: request,
          )
          .timeout(const Duration(seconds: 20));
      if (!valid) return;
      await db.transaction(() async {
        await put('revision:$key', '${result['revision']}');
        await (db.delete(
          db.syncOutbox,
        )..where((t) => t.operationId.equals(command.operationId))).go();
        await (db.delete(
          db.syncMetadata,
        )..where((t) => t.key.equals(requestKey))).go();
      });
    } on PostgrestException catch (e) {
      if (e.code != '40001' || !valid) rethrow;
      // Server wins conflicts, including tombstones. Clear only this entity's edits.
      final table = command.operation.startsWith('intake.')
          ? 'water_intakes'
          : command.operation.startsWith('goal.')
          ? 'daily_goals'
          : 'profiles';
      var query = client!.from(table).select().eq('user_id', owner);
      if (table == 'water_intakes') query = query.eq('id', command.entityId);
      if (table == 'daily_goals') {
        query = query.eq('local_day', command.entityId);
      }
      final remote = await query.single().timeout(const Duration(seconds: 20));
      if (!valid) return;
      await db.transaction(() async {
        final obsolete = (await queue()).where(
          (r) => entityKey(r.operation, r.entityId) == key,
        );
        for (final row in obsolete) {
          await (db.delete(
            db.syncOutbox,
          )..where((t) => t.operationId.equals(row.operationId))).go();
          await (db.delete(
            db.syncMetadata,
          )..where((t) => t.key.equals('command:${row.operationId}'))).go();
        }
        await apply(table, remote);
      });
      conflicts++;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAll(
    String table,
    String order,
  ) async {
    final all = <Map<String, dynamic>>[];
    for (var offset = 0; valid; offset += 500) {
      final rows = await client!
          .from(table)
          .select()
          .eq('user_id', owner)
          .order(order)
          .range(offset, offset + 499)
          .timeout(const Duration(seconds: 20));
      if (!valid) return [];
      all.addAll(rows);
      if (rows.length < 500) break;
    }
    return all;
  }

  Future<void> pull() async {
    final profiles = await fetchAll('profiles', 'user_id');
    final goals = await fetchAll('daily_goals', 'local_day');
    final intakes = await fetchAll('water_intakes', 'id');
    if (!valid) return;
    await db.transaction(() async {
      final pendingKeys = (await queue())
          .map((r) => entityKey(r.operation, r.entityId))
          .toSet();
      for (final group in {
        'profiles': profiles,
        'daily_goals': goals,
        'water_intakes': intakes,
      }.entries) {
        for (final row in group.value) {
          final key = remoteKey(group.key, row);
          if (!pendingKeys.contains(key)) {
            await apply(group.key, row);
          } else if (await metadata('revision:$key') == null) {
            // Initial import may target an existing profile/day. Existing baselines
            // are never advanced past unsent offline changes.
            await put('revision:$key', '${row['revision']}');
          }
        }
      }
    });
  }

  String remoteKey(String table, Map<String, dynamic> row) => switch (table) {
    'profiles' => 'preferences:preferences',
    'daily_goals' => 'goal:${row['local_day']}',
    _ => 'intake:${row['id']}',
  };
  Future<void> apply(String table, Map<String, dynamic> row) async {
    await put('revision:${remoteKey(table, row)}', '${row['revision']}');
    switch (table) {
      case 'profiles':
        await (db.update(
          db.appPreferences,
        )..where((t) => t.id.equals(1))).write(
          AppPreferencesCompanion(
            goal: Value(row['daily_goal'] as int),
            startMinute: Value(row['start_minute'] as int),
            endMinute: Value(row['end_minute'] as int),
            age: Value((row['age'] as int?) ?? 26),
            weight: Value((row['weight'] as num?)?.toDouble() ?? 60),
            height: Value((row['height'] as num?)?.toDouble() ?? 165),
            sex: Value(row['sex'] as String),
            pet: Value((row['pet'] as String?) ?? 'cat'),
            onboarded: const Value(true),
          ),
        );
      case 'daily_goals':
        final day = row['local_day'] as String;
        await db
            .into(db.dailyGoals)
            .insert(
              DailyGoalsCompanion.insert(day: day, goal: row['goal'] as int),
              mode: InsertMode.insertOrIgnore,
            );
        await (db.update(db.dailyGoals)..where((t) => t.day.equals(day))).write(
          DailyGoalsCompanion(goal: Value(row['goal'] as int)),
        );
      case 'water_intakes':
        await db
            .into(db.intakeRecords)
            .insertOnConflictUpdate(
              IntakeRecordsCompanion.insert(
                id: row['id'] as String,
                ownerId: Value(owner),
                amount: row['amount'] as int,
                occurredAt: DateTime.parse(row['occurred_at'] as String)
                    .toUtc(),
                localDay: row['local_day'] as String,
                offsetMinutes: row['offset_minutes'] as int,
                onTime: row['on_time'] as bool,
                deleted: Value(row['deleted'] as bool),
              ),
            );
    }
  }

  /// Explicit user action; the guest journal binds the source to one account.
  /// Target transaction + stable IDs make restart/retry safe before journal commit.
  Future<void> importGuest(HydrationRepository guest) async {
    if (!authenticated || !valid) throw StateError('Sign in first');
    await sync();
    if (error != null || !valid) throw StateError('Sync before importing');
    await guest.initialize();
    final marker = await (guest.db.select(
      guest.db.syncMetadata,
    )..where((t) => t.key.equals('claimed-by'))).getSingleOrNull();
    if (marker != null && marker.value != owner) {
      throw StateError('Guest already claimed');
    }
    final rows = await (guest.db.select(
      guest.db.intakeRecords,
    )..where((t) => t.deleted.equals(false))).get();
    final goals = await guest.db.select(guest.db.dailyGoals).get();
    final prefs = (await guest.snapshot()).preferences;
    if (!valid) return;
    await db.transaction(() async {
      final empty = (await db.select(db.intakeRecords).get()).isEmpty;
      for (final row in rows) {
        final exists = await (db.select(
          db.intakeRecords,
        )..where((t) => t.id.equals(row.id))).getSingleOrNull();
        if (exists != null) continue; // Includes remote tombstones.
        await db
            .into(db.intakeRecords)
            .insert(row.toCompanion(false).copyWith(ownerId: Value(owner)));
        await enqueue(row.id, 'intake.upsert', {
          'id': row.id,
          'amount': row.amount,
          'occurred_at': row.occurredAt.toUtc().toIso8601String(),
          'local_day': row.localDay,
          'offset_minutes': row.offsetMinutes,
          'on_time': row.onTime,
          'deleted': false,
        });
      }
      for (final goal in goals) {
        if (await metadata('revision:goal:${goal.day}') != null) continue;
        await db
            .into(db.dailyGoals)
            .insertOnConflictUpdate(goal.toCompanion(false));
        await enqueue(goal.day, 'goal.upsert', {
          'local_day': goal.day,
          'goal': goal.goal,
        });
      }
      if (empty &&
          await metadata('revision:preferences:preferences') == '1' &&
          prefs.onboarded) {
        await repository.savePreferences(prefs.copyWith(notifications: false));
      }
      await put('guest-imported', owner);
    });
    await guest.db
        .into(guest.db.syncMetadata)
        .insertOnConflictUpdate(
          SyncMetadataCompanion.insert(key: 'claimed-by', value: owner),
        );
    await sync();
  }

  Future<void> enqueue(
    String id,
    String operation,
    Map<String, dynamic> payload,
  ) => db
      .into(db.syncOutbox)
      .insert(
        SyncOutboxCompanion.insert(
          operationId: const Uuid().v4(),
          ownerId: Value(owner),
          entityId: id,
          operation: operation,
          payload: jsonEncode(payload),
          createdAt: DateTime.now().toUtc(),
        ),
      );

  Future<void> close() async {
    stopped = true;
    timer?.cancel();
    debounce?.cancel();
    await subscription?.cancel();
    await _running;
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}
