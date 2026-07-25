import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';


import 'package:drift/drift.dart';

import '../providers/api_providers.dart';
import 'database.dart';
import 'database_provider.dart';

class CacheService {
  final AppDatabase _db;

  CacheService(this._db);

  /// Serializes [DashboardData] and upserts it into the cache table.
  Future<void> cacheDashboard(DashboardData data) async {
    await _db.into(_db.cachedDashboard).insertOnConflictUpdate(
          CachedDashboardCompanion(
            id: const Value(1),
            json: Value(jsonEncode(data.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Returns the cached [DashboardData] or null if no cache exists.
  Future<DashboardData?> getCachedDashboard() async {
    final row = await _db.select(_db.cachedDashboard).getSingleOrNull();
    if (row == null) return null;
    final map = jsonDecode(row.json) as Map<String, dynamic>;
    return DashboardData.fromJson(map);
  }

  /// Queues a transaction for offline sync.
  /// Returns the generated id for the queued transaction.
  Future<String> queueTransaction(
      String type, Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.into(_db.offlineTransactions).insert(
          OfflineTransactionsCompanion(
            id: Value(id),
            type: Value(type),
            json: Value(jsonEncode(data)),
            createdAt: Value(DateTime.now()),
          ),
        );
    return id;
  }

  /// Returns all transactions that have not been synced yet.
  Future<List<OfflineTransaction>> getPendingSyncTransactions() async {
    return (_db.select(_db.offlineTransactions)
          ..where((t) => t.syncedAt.isNull()))
        .get();
  }

  /// Marks a queued transaction as synced.
  Future<void> markSynced(String id) async {
    await (_db.update(_db.offlineTransactions)
          ..where((t) => t.id.equals(id)))
        .write(OfflineTransactionsCompanion(
          syncedAt: Value(DateTime.now()),
        ));
  }
}

final cacheServiceProvider = Provider<CacheService>((ref) {
  final db = ref.watch(databaseProvider);
  return CacheService(db);
});
