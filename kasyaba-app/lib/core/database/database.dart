import 'package:drift/drift.dart';

part 'database.g.dart';

class CachedDashboard extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();
}

class OfflineTransactions extends Table {
  TextColumn get id => text()();

  // Nullable for a backwards-compatible migration. New records always carry
  // the authenticated user id so queued data cannot cross account boundaries.
  TextColumn get userId => text().nullable()();

  TextColumn get type => text()();

  TextColumn get json => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn? get syncedAt => dateTime().nullable()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  TextColumn? get lastError => text().nullable()();

  DateTimeColumn? get failedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [CachedDashboard, OfflineTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(offlineTransactions, offlineTransactions.userId);
      }
      if (from < 3) {
        await m.addColumn(offlineTransactions, offlineTransactions.retryCount);
        await m.addColumn(offlineTransactions, offlineTransactions.lastError);
        await m.addColumn(offlineTransactions, offlineTransactions.failedAt);
      }
    },
  );
}
