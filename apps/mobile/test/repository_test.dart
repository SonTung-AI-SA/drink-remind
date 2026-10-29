import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_island/core/database/app_database.dart';
import 'package:little_island/features/hydration/data/hydration_repository.dart';
import 'package:little_island/features/hydration/domain/models.dart';
import 'package:little_island/features/sync/sync_engine.dart';

void main() {
  late AppDatabase db;
  late HydrationRepository repo;
  var time = DateTime(2026, 10, 28, 8);
  setUp(() async {
    time = DateTime(2026, 10, 28, 8);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = HydrationRepository(db, clock: () => time);
    await repo.initialize();
  });
  tearDown(() async => db.close());
  test('initializing twice does not duplicate singleton preferences', () async {
    await repo.initialize();
    expect((await db.select(db.appPreferences).get()).length, 1);
    expect((await repo.snapshot()).preferences.goal, 2000);
  });
  test('watch exposes the saved onboarding state', () async {
    await repo.savePreferences(const Preferences(onboarded: true, pet: 'fish'));
    final data = await repo.watch().first;
    expect(data.preferences.onboarded, isTrue);
    expect(data.preferences.pet, 'fish');
  });
  test('record and outbox commit together, edit/delete recalculate', () async {
    final id = await repo.record(250);
    expect((await repo.snapshot()).totalOn(time), 250);
    expect((await db.select(db.syncOutbox).get()).length, 2);
    await repo.updateAmount(id, 350);
    expect((await repo.snapshot()).totalOn(time), 350);
    await repo.delete(id);
    final data = await repo.snapshot();
    expect(data.totalOn(time), 0);
    expect(data.meals, 0);
    expect((await db.select(db.syncOutbox).get()).length, 4);
    expect((await db.select(db.intakeRecords).get()).single.deleted, isTrue);
  });
  test('screen refresh does not move persisted reminder times', () async {
    final before = (await repo.snapshot()).plans[dayKey(time)]!;
    time = time.add(const Duration(minutes: 10));
    await repo.ensureDay();
    final after = (await repo.snapshot()).plans[dayKey(time)]!;
    expect(after.map((s) => s.at), before.map((s) => s.at));
  });
  test(
    'day rollover keeps history and goal changes affect only today',
    () async {
      await repo.record(250);
      final yesterday = time;
      time = DateTime(2026, 10, 29, 8);
      await repo.ensureDay();
      await repo.savePreferences(
        const Preferences(goal: 1500, onboarded: true),
      );
      final data = await repo.snapshot();
      expect(data.totalOn(yesterday), 250);
      expect(data.totalOn(time), 0);
      expect(data.goalOn(yesterday), 2000);
      expect(data.goalOn(time), 1500);
    },
  );
  test('invalid mutation leaves data and outbox unchanged', () async {
    await expectLater(repo.record(-1), throwsFormatException);
    expect((await repo.snapshot()).intakes, isEmpty);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });
  test(
    'outbox preserves edit order when device clock moves backwards',
    () async {
      final id = await repo.record(250);
      time = time.subtract(const Duration(hours: 1));
      await repo.updateAmount(id, 350);
      final engine = SyncEngine(repo, null, 'local-device');
      final commands = (await engine.queue())
          .where((r) => r.entityId == id)
          .toList();
      expect(commands.first.payload, contains('250'));
      expect(commands.last.payload, contains('350'));
      await engine.close();
      engine.dispose();
    },
  );
}
