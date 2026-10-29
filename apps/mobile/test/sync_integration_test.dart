// Real Auth + PostgREST + SQLite checks. Run through scripts/test-mobile-sync.ps1.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:little_island/core/database/app_database.dart';
import 'package:little_island/features/hydration/data/hydration_repository.dart';
import 'package:little_island/features/hydration/domain/models.dart';
import 'package:little_island/features/sync/sync_engine.dart';

class NetworkSwitch extends http.BaseClient {
  final inner = http.Client();
  bool offline = false, loseRpcResponse = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (offline) throw const SocketException('Synthetic offline');
    final result = await inner.send(request);
    if (loseRpcResponse && request.url.path.contains('/rpc/')) {
      loseRpcResponse = false;
      await result.stream.drain<void>();
      throw const SocketException(
        'Synthetic lost response after server commit',
      );
    }
    return result;
  }

  @override
  void close() => inner.close();
}

void main() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  final secret = Platform.environment['MIZU_TEST_SERVICE_KEY'];
  test(
    'real backend: restore, offline/replay, conflict, tombstone, merge, isolation and pagination',
    () async {
      expect(['127.0.0.1', 'localhost'].contains(Uri.parse(url).host), isTrue);
      final admin = SupabaseClient(url, secret!);
      final network = NetworkSwitch();
      final a = SupabaseClient(url, key, httpClient: network);
      final b = SupabaseClient(url, key);
      final other = SupabaseClient(url, key);
      final users = <String>[];
      final databases = <AppDatabase>[];
      final engines = <SyncEngine>[];
      HydrationRepository device(String owner) {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        databases.add(db);
        return HydrationRepository(db, ownerId: owner);
      }

      SyncEngine engine(
        HydrationRepository repo,
        SupabaseClient client,
        String owner,
      ) {
        final sync = SyncEngine(repo, client, owner);
        engines.add(sync);
        return sync;
      }

      try {
        final email = 'sync-${const Uuid().v4()}@example.invalid';
        final password = '${const Uuid().v4()}aB!9';
        final signup = await admin.auth.admin.createUser(
          AdminUserAttributes(
            email: email,
            password: password,
            emailConfirm: true,
          ),
        );
        final owner = signup.user!.id;
        users.add(owner);
        await a.auth.signInWithPassword(email: email, password: password);
        await b.auth.signInWithPassword(email: email, password: password);
        final otherEmail = 'sync-${const Uuid().v4()}@example.invalid';
        final otherSignup = await admin.auth.admin.createUser(
          AdminUserAttributes(
            email: otherEmail,
            password: password,
            emailConfirm: true,
          ),
        );
        users.add(otherSignup.user!.id);
        await other.auth.signInWithPassword(
          email: otherEmail,
          password: password,
        );
        final ra = device(owner), rb = device(owner);
        await ra.initialize();
        await rb.initialize();
        final sa = engine(ra, a, owner), sb = engine(rb, b, owner);
        await sa.sync();
        await sb.sync();
        expect(sa.error, isNull);

        await ra.savePreferences(
          const Preferences(goal: 1500, onboarded: true, pet: 'dog'),
        );
        final id = await ra.record(250);
        await sa.sync();
        await sb.sync();
        expect(sa.error, isNull);
        expect(sb.error, isNull);
        expect((await rb.snapshot()).totalOn(DateTime.now()), 250);
        expect((await rb.snapshot()).preferences.goal, 1500);
        expect((await rb.snapshot()).preferences.pet, 'dog');
        expect(
          await other.from('water_intakes').select(),
          isEmpty,
          reason: 'RLS separates users',
        );

        network.offline = true;
        await ra.updateAmount(id, 350);
        await sa.sync();
        expect(sa.error, isNotNull);
        expect(await sa.queue(), isNotEmpty);
        expect((await ra.snapshot()).totalOn(DateTime.now()), 350);
        network.offline = false;
        network.loseRpcResponse = true;
        await sa.sync();
        expect(sa.error, isNotNull, reason: 'Committed response was lost');
        final restart = engine(ra, a, owner);
        await restart.sync();
        await sb.sync();
        expect(restart.error, isNull);
        expect(await restart.queue(), isEmpty);
        final remote = await b
            .from('water_intakes')
            .select()
            .eq('id', id)
            .single();
        expect(
          remote['revision'],
          2,
          reason: 'Replay must not increment twice',
        );
        expect((await rb.snapshot()).totalOn(DateTime.now()), 350);

        // A edits against rev2; B commits rev3. Server wins A's stale edit.
        await ra.updateAmount(id, 450);
        await rb.updateAmount(id, 550);
        await sb.sync();
        await restart.sync();
        expect(restart.conflicts, 1);
        expect((await ra.snapshot()).totalOn(DateTime.now()), 550);
        // A edits while B deletes; no resurrection on next sync.
        await ra.updateAmount(id, 650);
        await rb.delete(id);
        await sb.sync();
        await restart.sync();
        expect((await ra.snapshot()).intakes, isEmpty);
        expect(await restart.queue(), isEmpty);

        // Profile and goal revisions also protect against stale offline writes.
        await ra.savePreferences(
          const Preferences(goal: 1800, onboarded: true),
        );
        await rb.savePreferences(
          const Preferences(goal: 2200, onboarded: true),
        );
        await sb.sync();
        await restart.sync();
        expect((await ra.snapshot()).preferences.goal, 2200);
        expect((await ra.snapshot()).goalOn(DateTime.now()), 2200);

        final guest = device('local-device');
        await guest.initialize();
        await guest.savePreferences(const Preferences(onboarded: true));
        final guestId = await guest.record(200);
        await restart.importGuest(guest);
        await restart.importGuest(guest);
        expect(restart.error, isNull);
        expect(
          (await a.from('water_intakes').select().eq('id', guestId)).length,
          1,
        );
        final laterGuestId = await guest.record(300);
        await restart.importGuest(guest);
        expect(
          (await a.from('water_intakes').select().eq('id', laterGuestId))
              .length,
          1,
          reason:
              'Later guest history can be added to the same claimed account',
        );
        final otherRepo = device(otherSignup.user!.id);
        await otherRepo.initialize();
        final otherEngine = engine(otherRepo, other, otherSignup.user!.id);
        await expectLater(otherEngine.importGuest(guest), throwsStateError);
        expect((await otherRepo.snapshot()).intakes, isEmpty);

        // >1000 entries must restore beyond the PostgREST default row cap.
        await admin
            .from('water_intakes')
            .insert(
              List.generate(
                1005,
                (index) => {
                  'id': const Uuid().v4(),
                  'user_id': owner,
                  'amount': 10,
                  'occurred_at': DateTime.utc(
                    2026,
                    1,
                    1,
                  ).add(Duration(minutes: index)).toIso8601String(),
                  'local_day': '2026-01-01',
                  'offset_minutes': 0,
                  'on_time': false,
                },
              ),
            );
        final newPhone = device(owner);
        await newPhone.initialize();
        final restore = engine(newPhone, b, owner);
        await restore.sync();
        expect(restore.error, isNull);
        expect((await newPhone.snapshot()).intakes.length, 1007);
        expect((await newPhone.snapshot()).preferences.goal, 2200);
        await a.auth.signOut(scope: SignOutScope.local);
        await ra.record(100);
        await restart.sync();
        expect(
          await restart.queue(),
          isNotEmpty,
          reason: 'Signed-out engine cannot send',
        );
        await a.auth.signInWithPassword(email: email, password: password);
        await restart.sync();
        expect(restart.error, isNull);
        expect(await restart.queue(), isEmpty);
      } finally {
        network.offline = false;
        for (final sync in engines) {
          await sync.close();
          sync.dispose();
        }
        for (final db in databases) {
          await db.close();
        }
        for (final id in users) {
          await admin.auth.admin.deleteUser(id);
        }
        await a.dispose();
        await b.dispose();
        await other.dispose();
        await admin.dispose();
      }
    },
    skip: url.isEmpty || secret == null
        ? 'Run scripts/test-mobile-sync.ps1 against local Supabase'
        : false,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
