import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../providers/api_providers.dart';
import 'database.dart';
import 'database_provider.dart';

class CacheService {
  final AppDatabase _db;
  static const _uuid = Uuid();

  CacheService(this._db);

  /// Serializes [DashboardData] for one user and upserts it into the cache table.
  ///
  /// The cache table intentionally keeps one small row, so the user id is
  /// stored inside the payload. This prevents a later offline session from
  /// reading the previous user's dashboard after an account switch.
  Future<void> cacheDashboard(DashboardData data, String userId) async {
    await _db
        .into(_db.cachedDashboard)
        .insertOnConflictUpdate(
          CachedDashboardCompanion(
            id: const Value(1),
            json: Value(jsonEncode({'userId': userId, 'data': data.toJson()})),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Returns the cached dashboard for [userId], or null if no matching cache exists.
  Future<DashboardData?> getCachedDashboard(String userId) async {
    final row = await _db.select(_db.cachedDashboard).getSingleOrNull();
    if (row == null) return null;
    try {
      final envelope = jsonDecode(row.json) as Map<String, dynamic>;
      if (envelope['userId'] != userId ||
          envelope['data'] is! Map<String, dynamic>) {
        return null;
      }
      return DashboardData.fromJson(envelope['data'] as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// Queues a transaction for offline sync.
  /// Returns the generated id for the queued transaction.
  Future<String> queueTransaction({
    required String type,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    // Millisecond timestamps collide when multiple entries are queued in one
    // event loop turn. UUIDs keep the primary key stable and collision-free.
    final id = _uuid.v4();
    await _db
        .into(_db.offlineTransactions)
        .insert(
          OfflineTransactionsCompanion(
            id: Value(id),
            userId: Value(userId),
            type: Value(type),
            json: Value(jsonEncode(data)),
            createdAt: Value(DateTime.now()),
          ),
        );
    return id;
  }

  /// Returns all transactions that have not been synced yet.
  Future<List<OfflineTransaction>> getPendingSyncTransactions(
    String userId,
  ) async {
    return (_db.select(_db.offlineTransactions)..where(
      (t) =>
          t.syncedAt.isNull() &
          t.failedAt.isNull() &
          t.userId.equals(userId),
    )).get();
  }

  /// Replays only transaction entries for the currently authenticated user.
  /// Network failures leave the row pending for the next connectivity event.
  Future<int> syncPendingTransactions(Dio dio, String userId) async {
    final pending = await getPendingSyncTransactions(userId);
    var syncedCount = 0;
    for (final transaction in pending) {
      try {
        final data = jsonDecode(transaction.json) as Map<String, dynamic>;
        final path = switch (transaction.type) {
          'expense' => '/expenses',
          'income' => '/income',
          'transfer' => '/transfers',
          _ => null,
        };

        // Older/unsupported queued operations must not be sent with an
        // ambiguous payload. Keep them out of the retry loop and expose the
        // reason so the user can understand what happened.
        if (path == null) {
          await markFailed(transaction.id, 'Unsupported offline operation');
          continue;
        }
        await dio.post(path, data: data);
        await markSynced(transaction.id);
        syncedCount++;
      } on DioException catch (error) {
        final message = _errorMessage(error);
        if (_isRetryable(error)) {
          await recordRetry(transaction, message);
        } else {
          await markFailed(transaction.id, message);
        }
      } on FormatException {
        await markFailed(transaction.id, 'Queued transaction data is invalid');
      } on TypeError {
        await markFailed(transaction.id, 'Queued transaction data is invalid');
      }
    }
    return syncedCount;
  }

  String _errorMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final err = responseData['error'];
      if (err is Map) {
        final msg = err['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    }
    return 'Sync failed (HTTP ${error.response?.statusCode ?? 'network'})';
  }

  bool _isRetryable(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.response?.statusCode == 408 ||
        error.response?.statusCode == 429 ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  /// Marks a queued transaction as synced.
  Future<void> markSynced(String id) async {
    await (_db.update(_db.offlineTransactions)..where((t) => t.id.equals(id)))
        .write(
          OfflineTransactionsCompanion(
            syncedAt: Value(DateTime.now()),
            lastError: const Value(null),
          ),
        );
  }

  Future<void> recordRetry(OfflineTransaction transaction, String message) async {
    final nextRetryCount = transaction.retryCount + 1;
    await (_db.update(_db.offlineTransactions)
          ..where((t) => t.id.equals(transaction.id)))
        .write(
          OfflineTransactionsCompanion(
            retryCount: Value(nextRetryCount),
            lastError: Value(message),
            failedAt: nextRetryCount >= 5
                ? Value(DateTime.now())
                : const Value(null),
          ),
        );
  }

  Future<void> markFailed(String id, String message) async {
    await (_db.update(_db.offlineTransactions)..where((t) => t.id.equals(id)))
        .write(
          OfflineTransactionsCompanion(
            failedAt: Value(DateTime.now()),
            lastError: Value(message),
          ),
        );
  }
}

final cacheServiceProvider = Provider<CacheService>((ref) {
  final db = ref.watch(databaseProvider);
  return CacheService(db);
});
