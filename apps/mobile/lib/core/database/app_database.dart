import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class AppPreferences extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get goal => integer().withDefault(const Constant(2000))();
  IntColumn get startMinute => integer().withDefault(const Constant(480))();
  IntColumn get endMinute => integer().withDefault(const Constant(1260))();
  IntColumn get age => integer().withDefault(const Constant(26))();
  RealColumn get weight => real().withDefault(const Constant(60))();
  RealColumn get height => real().withDefault(const Constant(165))();
  TextColumn get sex => text().withDefault(const Constant('unspecified'))();
  TextColumn get pet => text().withDefault(const Constant('cat'))();
  BoolColumn get notifications =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get onboarded => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class IntakeRecords extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId =>
      text().withDefault(const Constant('local-device'))();
  IntColumn get amount => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get localDay => text()();
  IntColumn get offsetMinutes => integer()();
  BoolColumn get onTime => boolean()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class DailyGoals extends Table {
  TextColumn get day => text()();
  IntColumn get goal => integer()();
  TextColumn get planJson => text().withDefault(const Constant('[]'))();
  @override
  Set<Column> get primaryKey => {day};
}

class SyncOutbox extends Table {
  TextColumn get operationId => text()();
  TextColumn get ownerId =>
      text().withDefault(const Constant('local-device'))();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {operationId};
}

class SyncMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [AppPreferences, IntakeRecords, DailyGoals, SyncOutbox, SyncMetadata],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({String name = 'little_island'})
    : super(
        driftDatabase(
          name: name,
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );
  AppDatabase.forTesting(super.executor);
  @override
  int get schemaVersion => 3;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(syncMetadata);
      if (from < 3) await m.addColumn(appPreferences, appPreferences.pet);
    },
  );
}
