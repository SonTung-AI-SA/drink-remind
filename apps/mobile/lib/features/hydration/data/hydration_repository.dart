import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/models.dart';

class HydrationRepository {
  HydrationRepository(
    this.db, {
    DateTime Function()? clock,
    this.ownerId = 'local-device',
  }) : now = clock ?? DateTime.now;
  final AppDatabase db;
  final String ownerId;
  final DateTime Function() now;
  static const _uuid = Uuid();

  Future<void> initialize() async {
    await db
        .into(db.appPreferences)
        .insert(
          const AppPreferencesCompanion(id: Value(1)),
          mode: InsertMode.insertOrIgnore,
        );
    await ensureDay();
  }

  Stream<HydrationSnapshot> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.appPreferences, db.intakeRecords, db.dailyGoals},
      )
      .watch()
      .asyncMap((_) => snapshot());

  Future<HydrationSnapshot> snapshot() async {
    final p = await db.select(db.appPreferences).getSingle();
    final records = await (db.select(
      db.intakeRecords,
    )..where((t) => t.deleted.equals(false))).get();
    final days = await db.select(db.dailyGoals).get();
    return HydrationSnapshot(
      preferences: Preferences(
        goal: p.goal,
        startMinute: p.startMinute,
        endMinute: p.endMinute,
        age: p.age,
        weight: p.weight,
        height: p.height,
        sex: p.sex,
        pet: p.pet,
        notifications: p.notifications,
        onboarded: p.onboarded,
      ),
      intakes: records
          .map(
            (r) => WaterIntake(
              id: r.id,
              amount: r.amount,
              at: r.occurredAt.toLocal(),
              day: r.localDay,
              onTime: r.onTime,
            ),
          )
          .toList(),
      goals: {for (final d in days) d.day: d.goal},
      plans: {
        for (final d in days)
          d.day: (jsonDecode(d.planJson) as List)
              .map((s) => ReminderSlot.fromJson(s as Map<String, dynamic>))
              .toList(),
      },
    );
  }

  Future<void> ensureDay() async {
    final day = dayKey(now());
    final existing = await (db.select(
      db.dailyGoals,
    )..where((t) => t.day.equals(day))).getSingleOrNull();
    if (existing != null) return;
    final data = await snapshot();
    await db.transaction(() async {
      await db
          .into(db.dailyGoals)
          .insert(
            DailyGoalsCompanion.insert(
              day: day,
              goal: data.preferences.goal,
              planJson: Value(
                jsonEncode(
                  buildReminderPlan(
                    now: now(),
                    preferences: data.preferences,
                    consumed: 0,
                  ).map((s) => s.toJson()).toList(),
                ),
              ),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    });
  }

  Future<void> _replan() async {
    final data = await snapshot(), date = now();
    final plan = buildReminderPlan(
      now: date,
      preferences: data.preferences,
      consumed: data.totalOn(date),
    );
    await (db.update(
      db.dailyGoals,
    )..where((t) => t.day.equals(dayKey(date)))).write(
      DailyGoalsCompanion(
        planJson: Value(jsonEncode(plan.map((s) => s.toJson()).toList())),
      ),
    );
  }

  Future<void> _enqueue(
    String id,
    String operation,
    Map<String, Object?> payload,
  ) => db
      .into(db.syncOutbox)
      .insert(
        SyncOutboxCompanion.insert(
          operationId: _uuid.v4(),
          ownerId: Value(ownerId),
          entityId: id,
          operation: operation,
          payload: jsonEncode(payload),
          createdAt: now().toUtc(),
        ),
      );

  Future<String> record(int amount) async {
    if (amount < 10 || amount > 2000) {
      throw const FormatException('Dung tích từ 10 đến 2.000 ml.');
    }
    await ensureDay();
    final id = _uuid.v4(), at = now();
    await db.transaction(() async {
      final data = await snapshot();
      final onTime = (data.plans[dayKey(at)] ?? []).any(
        (s) => s.at.difference(at).inMinutes.abs() <= 15,
      );
      await db
          .into(db.intakeRecords)
          .insert(
            IntakeRecordsCompanion.insert(
              id: id,
              ownerId: Value(ownerId),
              amount: amount,
              occurredAt: at.toUtc(),
              localDay: dayKey(at),
              offsetMinutes: at.timeZoneOffset.inMinutes,
              onTime: onTime,
            ),
          );
      await _enqueue(id, 'intake.upsert', {
        'id': id,
        'amount': amount,
        'occurred_at': at.toUtc().toIso8601String(),
        'local_day': dayKey(at),
        'offset_minutes': at.timeZoneOffset.inMinutes,
        'on_time': onTime,
        'deleted': false,
      });
      final today = await (db.select(
        db.dailyGoals,
      )..where((t) => t.day.equals(dayKey(at)))).getSingle();
      final known =
          await (db.select(db.syncMetadata)
                ..where((t) => t.key.equals('revision:goal:${dayKey(at)}')))
              .getSingleOrNull();
      final pendingGoal =
          await (db.select(db.syncOutbox)..where(
                (t) =>
                    t.entityId.equals(dayKey(at)) &
                    t.operation.equals('goal.upsert'),
              ))
              .get();
      if (known == null && pendingGoal.isEmpty) {
        await _enqueue(dayKey(at), 'goal.upsert', {
          'local_day': dayKey(at),
          'goal': today.goal,
        });
      }
      await _replan();
    });
    return id;
  }

  Future<void> delete(String id) => db.transaction(() async {
    await (db.update(db.intakeRecords)..where((t) => t.id.equals(id))).write(
      const IntakeRecordsCompanion(deleted: Value(true)),
    );
    await _enqueue(id, 'intake.delete', {'id': id, 'deleted': true});
    await _replan();
  });

  Future<void> updateAmount(String id, int amount) async {
    if (amount < 10 || amount > 2000) {
      throw const FormatException('Dung tích từ 10 đến 2.000 ml.');
    }
    await db.transaction(() async {
      final row = await (db.select(
        db.intakeRecords,
      )..where((t) => t.id.equals(id) & t.deleted.equals(false))).getSingle();
      await (db.update(db.intakeRecords)..where((t) => t.id.equals(id))).write(
        IntakeRecordsCompanion(amount: Value(amount)),
      );
      await _enqueue(id, 'intake.upsert', {
        'id': id,
        'amount': amount,
        'occurred_at': row.occurredAt.toUtc().toIso8601String(),
        'local_day': row.localDay,
        'offset_minutes': row.offsetMinutes,
        'on_time': row.onTime,
        'deleted': false,
      });
      await _replan();
    });
  }

  Future<void> savePreferences(Preferences p) async {
    p.validate();
    await ensureDay();
    await db.transaction(() async {
      await (db.update(db.appPreferences)..where((t) => t.id.equals(1))).write(
        AppPreferencesCompanion(
          goal: Value(p.goal),
          startMinute: Value(p.startMinute),
          endMinute: Value(p.endMinute),
          age: Value(p.age),
          weight: Value(p.weight),
          height: Value(p.height),
          sex: Value(p.sex),
          pet: Value(p.pet),
          notifications: Value(p.notifications),
          onboarded: Value(p.onboarded),
        ),
      );
      await (db.update(db.dailyGoals)
            ..where((t) => t.day.equals(dayKey(now()))))
          .write(DailyGoalsCompanion(goal: Value(p.goal)));
      await _enqueue('preferences', 'preferences.upsert', {
        'goal': p.goal,
        'start_minute': p.startMinute,
        'end_minute': p.endMinute,
        'age': p.age,
        'weight': p.weight,
        'height': p.height,
        'sex': p.sex,
        'pet': p.pet,
      });
      await _enqueue(dayKey(now()), 'goal.upsert', {
        'local_day': dayKey(now()),
        'goal': p.goal,
      });
      await _replan();
    });
  }

  Future<void> replanAfterSync() async {
    await ensureDay();
    await _replan();
  }
}
