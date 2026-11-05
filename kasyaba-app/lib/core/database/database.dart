import 'dart:convert';

import 'package:drift/drift.dart';

part 'database.g.dart';

class CachedSnapshots extends Table {
  TextColumn get userId => text()();

  TextColumn get key => text()();

  TextColumn get json => text()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, key};
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

@DriftDatabase(tables: [CachedSnapshots, OfflineTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

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
      if (from < 4) {
        await m.createTable(cachedSnapshots);
        // Migrate the single legacy dashboard row into the unified snapshot
        // store. The old table stored an envelope {userId, data}; only that
        // payload can be attributed to a user, so malformed rows are dropped.
        final legacyRows = await customSelect(
          'SELECT json, updated_at FROM cached_dashboard',
        ).get();
        for (final row in legacyRows) {
          final rawJson = row.read<String>('json');
          final updatedAt = row.read<DateTime>('updated_at');
          try {
            final decoded =
                const JsonDecoder().convert(rawJson) as Map<String, dynamic>;
            final userId = decoded['userId']?.toString();
            final data = decoded['data'];
            if (userId == null ||
                userId.isEmpty ||
                data is! Map<String, dynamic>) {
              continue;
            }
            await into(cachedSnapshots).insertOnConflictUpdate(
              CachedSnapshotsCompanion.insert(
                userId: userId,
                key: 'dashboard',
                json: const JsonEncoder().convert(data),
                fetchedAt: updatedAt,
              ),
            );
          } on FormatException {
            continue;
          } on TypeError {
            continue;
          }
        }
        await customStatement('DROP TABLE IF EXISTS cached_dashboard');
      }
    },
  );
}
