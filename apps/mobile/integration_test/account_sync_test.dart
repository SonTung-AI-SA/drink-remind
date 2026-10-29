import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:little_island/main.dart' as app;
import 'package:little_island/app/island_app.dart';
import 'package:little_island/app/providers.dart';
import 'package:little_island/core/backend/backend_config.dart';
import 'package:little_island/core/backend/secure_auth_storage.dart';
import 'package:little_island/core/database/app_database.dart';
import 'package:little_island/features/hydration/data/hydration_repository.dart';
import 'package:little_island/features/sync/sync_engine.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android account, secure session, upload, restore and logout', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(IslandApp)),
    );
    final account = container.read(accountProvider);
    final guest = container.read(guestRepositoryProvider);
    await guest.initialize();
    final before = (await guest.snapshot()).intakes.length;
    try {
      // Exercise the real app controller against a synthetic local fixture.
      // OAuth provider screens are intentionally excluded until configured.
      await account.localLogin(
        const String.fromEnvironment('TEST_EMAIL'),
        const String.fromEnvironment('TEST_PASSWORD'),
      );
      expect(account.error, isNull);
      expect(account.user, isNotNull);
      await tester.pumpAndSettle();
      final engine = container.read(syncProvider);
      await engine.sync();
      await tester.pumpAndSettle();
      expect(engine.error, isNull);
      final repo = container.read(repositoryProvider);
      await repo.savePreferences(
        (await repo.snapshot()).preferences.copyWith(pet: 'fish'),
      );
      await repo.record(300);
      await engine.sync();
      await tester.pumpAndSettle();
      expect(engine.error, isNull);
      expect(find.textContaining('300'), findsWidgets);
      final saved = await SecureAuthStorage(BackendConfig.namespace)
          .accessToken();
      expect(saved, isNotNull);
      expect((jsonDecode(saved!) as Map)['user']['id'], account.user!.id);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final replica = HydrationRepository(db, ownerId: account.owner);
      final restore = SyncEngine(replica, account.client, account.owner);
      try {
        await replica.initialize();
        await restore.sync();
        expect(restore.error, isNull);
        expect((await replica.snapshot()).totalOn(DateTime.now()), 300);
        expect((await replica.snapshot()).preferences.pet, 'fish');
      } finally {
        await restore.close();
        restore.dispose();
        await db.close();
      }

      await account.signOut();
      await tester.pumpAndSettle();
      expect(account.user, isNull);
      expect(
        (await container.read(repositoryProvider).snapshot()).intakes.length,
        before,
      );
      expect(
        await SecureAuthStorage(BackendConfig.namespace).accessToken(),
        isNull,
      );
    } finally {
      if (account.user != null) await account.signOut();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
