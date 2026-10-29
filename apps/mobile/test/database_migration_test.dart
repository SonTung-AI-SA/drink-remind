import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_island/core/database/app_database.dart';
import 'package:little_island/features/hydration/data/hydration_repository.dart';

void main() {
  test('v1 upgrade preserves guest intake and outbox', () async {
    final directory = await Directory.systemTemp.createTemp('mizu-migration-');
    final file = File('${directory.path}/guest.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final repo = HydrationRepository(db);
      await repo.initialize();
      final id = await repo.record(250);
      await db.customStatement('DROP TABLE sync_metadata');
      await db.customStatement('ALTER TABLE app_preferences DROP COLUMN pet');
      await db.customStatement('PRAGMA user_version = 1');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      final upgraded = HydrationRepository(db);
      await upgraded.initialize();
      expect((await upgraded.snapshot()).intakes.single.id, id);
      expect((await upgraded.snapshot()).totalOn(DateTime.now()), 250);
      expect(await db.select(db.syncOutbox).get(), hasLength(2));
      expect(await db.select(db.syncMetadata).get(), isEmpty);
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}
