import 'package:drift/drift.dart';

part 'database.g.dart';

class CachedDashboard extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();
}

class OfflineTransactions extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()();

  TextColumn get json => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn? get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [CachedDashboard, OfflineTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
