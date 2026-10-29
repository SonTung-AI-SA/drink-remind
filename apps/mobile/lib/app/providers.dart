import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/database/app_database.dart';
import '../core/notifications/reminder_service.dart';
import '../features/hydration/data/hydration_repository.dart';
import '../features/hydration/domain/models.dart';
import '../features/account/account_controller.dart';
import '../features/sync/sync_engine.dart';
import '../core/backend/backend_config.dart';

final backendClientProvider = Provider<SupabaseClient?>((ref) => null);
final backendErrorProvider = Provider<String?>((ref) => null);
final accountProvider = ChangeNotifierProvider<AccountController>(
  (ref) => AccountController(
    ref.watch(backendClientProvider),
    initializationError: ref.watch(backendErrorProvider),
  ),
);
final guestDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
final guestRepositoryProvider = Provider<HydrationRepository>(
  (ref) => HydrationRepository(ref.watch(guestDatabaseProvider)),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final owner = ref.watch(accountProvider.select((a) => a.owner));
  if (owner == 'local-device') return ref.watch(guestDatabaseProvider);
  final db = AppDatabase(
    name: 'little_island_${BackendConfig.namespace}_$owner',
  );
  ref.onDispose(db.close);
  return db;
});
final repositoryProvider = Provider<HydrationRepository>(
  (ref) => HydrationRepository(
    ref.watch(databaseProvider),
    ownerId: ref.watch(accountProvider.select((a) => a.owner)),
  ),
);
final syncProvider = ChangeNotifierProvider<SyncEngine>((ref) {
  final engine = SyncEngine(
    ref.watch(repositoryProvider),
    ref.watch(backendClientProvider),
    ref.watch(accountProvider.select((a) => a.owner)),
  );
  // Initialization is shared with hydrationProvider and is idempotent.
  Future.microtask(engine.start).catchError((Object _) {
    if (!engine.stopped) {
      engine.error = 'Chưa khởi động được đồng bộ. Hãy mở lại app.';
      engine.changed();
    }
  });
  return engine;
});
final reminderProvider = Provider<ReminderService>((ref) => ReminderService());
final hydrationProvider = StreamProvider<HydrationSnapshot>((ref) async* {
  final repository = ref.watch(repositoryProvider);
  await repository.initialize();
  yield* repository.watch();
});
