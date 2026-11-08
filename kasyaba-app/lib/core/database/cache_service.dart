import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../api/category_resolver.dart';
import 'database.dart';
import 'database_provider.dart';

class CacheService {
  final AppDatabase _db;
  static const _uuid = Uuid();

  static const String snapshotKeyDashboard = 'dashboard';
  static const String snapshotKeyAccounts = 'accounts';
  static const String snapshotKeyCategories = 'categories';
  static const String snapshotKeyBills = 'bills';
  static const String snapshotKeyGoals = 'goals';
  static const String snapshotKeyBudgets = 'budgets';
  static const String snapshotKeyAlerts = 'alerts';
  static const String snapshotKeyBalances = 'balances';

  static const int maxTransactionSnapshots = 10;
  static const String _transactionSnapshotPrefix = 'transactions:';

  CacheService(this._db);

  /// A stable key for a paginated transaction view.
  static String transactionsKey({int page = 1, DateTime? from, DateTime? to}) {
    String datePart(DateTime? value) {
      if (value == null) return 'all';
      // Match the date string sent as the `from`/`to` query parameter.
      return value.toIso8601String().split('T')[0];
    }

    return '${_transactionSnapshotPrefix}page:$page:'
        'from:${datePart(from)}:to:${datePart(to)}';
  }

  /// Upserts a JSON snapshot for one user and key.
  Future<void> putSnapshot({
    required String userId,
    required String key,
    required String json,
    DateTime? fetchedAt,
  }) async {
    await _db
        .into(_db.cachedSnapshots)
        .insertOnConflictUpdate(
          CachedSnapshotsCompanion.insert(
            userId: userId,
            key: key,
            json: json,
            fetchedAt: fetchedAt ?? DateTime.now(),
          ),
        );
    if (key.startsWith(_transactionSnapshotPrefix)) {
      await _pruneTransactionSnapshots(userId);
    }
  }

  /// Returns a stored snapshot for [userId]/[key], or null when absent.
  Future<({String json, DateTime fetchedAt})?> getSnapshot(
    String userId,
    String key,
  ) async {
    final row =
        await (_db.select(_db.cachedSnapshots)
              ..where((t) => t.userId.equals(userId) & t.key.equals(key)))
            .getSingleOrNull();
    if (row == null) return null;
    return (json: row.json, fetchedAt: row.fetchedAt);
  }

  /// Clears every read snapshot for [userId] while keeping the offline queue.
  Future<void> deleteSnapshotsFor(String userId) async {
    await (_db.delete(
      _db.cachedSnapshots,
    )..where((t) => t.userId.equals(userId))).go();
  }

  /// Clears every snapshot and queued mutation for [userId].
  Future<void> deleteAllForUser(String userId) async {
    await (_db.delete(
      _db.cachedSnapshots,
    )..where((t) => t.userId.equals(userId))).go();
    await (_db.delete(
      _db.offlineTransactions,
    )..where((t) => t.userId.equals(userId))).go();
  }

  Future<void> _pruneTransactionSnapshots(String userId) async {
    final rows =
        await (_db.select(_db.cachedSnapshots)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.key.like('$_transactionSnapshotPrefix%'),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.fetchedAt),
                (t) => OrderingTerm.asc(t.key),
              ]))
            .get();
    if (rows.length <= maxTransactionSnapshots) return;

    final staleKeys = rows
        .take(rows.length - maxTransactionSnapshots)
        .map((row) => row.key)
        .toList();
    await (_db.delete(
      _db.cachedSnapshots,
    )..where((t) => t.userId.equals(userId) & t.key.isIn(staleKeys))).go();
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
        ))
        .get();
  }

  /// Returns all offline transactions for [userId] (both pending and failed).
  Future<List<OfflineTransaction>> getAllOfflineTransactions(
    String userId,
  ) async {
    return (_db.select(_db.offlineTransactions)
          ..where((t) => t.syncedAt.isNull() & t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Watches all transactions for [userId] that have not been synced yet.
  Stream<List<OfflineTransaction>> watchPendingSyncTransactions(String userId) {
    return (_db.select(_db.offlineTransactions)..where(
          (t) =>
              t.syncedAt.isNull() &
              t.failedAt.isNull() &
              t.userId.equals(userId),
        ))
        .watch();
  }

  /// Replays only transaction entries for the currently authenticated user.
  /// Network failures leave the row pending for the next connectivity event.
  Future<int> syncPendingTransactions(Dio dio, String userId) async {
    final pending = await getPendingSyncTransactions(userId);
    var syncedCount = 0;
    for (final transaction in pending) {
      try {
        final data = jsonDecode(transaction.json) as Map<String, dynamic>;
        String? path;
        Map<String, dynamic> payload = data;

        if (transaction.type == 'expense') {
          final categoryId = data['categoryId']?.toString() ?? '';
          if (!isCategoryUuid(categoryId)) {
            final categoryName = data['categoryName']?.toString().trim();
            if (categoryName == null || categoryName.isEmpty) {
              await markFailed(
                transaction.id,
                'Choose an expense category first.',
              );
              continue;
            }
            // The queue stores a placeholder category id (often a legacy
            // `cat_food` value). Resolve it against the server right before
            // replay so the UUID is current even after several offline days.
            data['categoryId'] = await resolveCategoryId(
              dio: dio,
              categoryId: categoryId,
              categoryName: categoryName,
            );
          }
          path = '/expenses';
        } else if (transaction.type == 'income') {
          path = '/income';
        } else if (transaction.type == 'transfer') {
          path = '/transfers';
        } else if (transaction.type == 'goal_contribution') {
          final goalId = data['goalId']?.toString();
          if (goalId == null || goalId.isEmpty) {
            await markFailed(
              transaction.id,
              'Queued goal contribution has no goal id',
            );
            continue;
          }
          payload = Map<String, dynamic>.from(data)..remove('goalId');
          path = '/goals/$goalId/contributions';
        }

        // Older/unsupported queued operations must not be sent with an
        // ambiguous payload. Keep them out of the retry loop and expose the
        // reason so the user can understand what happened.
        if (path == null) {
          await markFailed(transaction.id, 'Unsupported offline operation');
          continue;
        }
        await dio.post(path, data: payload);
        await markSynced(transaction.id);
        syncedCount++;
      } on CategoryResolutionException catch (error) {
        if (error.queueable) {
          await recordRetry(transaction, error.message);
        } else {
          await markFailed(transaction.id, error.message);
        }
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
    await (_db.update(
      _db.offlineTransactions,
    )..where((t) => t.id.equals(id))).write(
      OfflineTransactionsCompanion(
        syncedAt: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> recordRetry(
    OfflineTransaction transaction,
    String message,
  ) async {
    final nextRetryCount = transaction.retryCount + 1;
    await (_db.update(
      _db.offlineTransactions,
    )..where((t) => t.id.equals(transaction.id))).write(
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
    await (_db.update(
      _db.offlineTransactions,
    )..where((t) => t.id.equals(id))).write(
      OfflineTransactionsCompanion(
        failedAt: Value(DateTime.now()),
        lastError: Value(message),
      ),
    );
  }

  /// Resets a failed offline transaction so it will be retried on next sync.
  Future<void> retryFailedTransaction(String id) async {
    await (_db.update(
      _db.offlineTransactions,
    )..where((t) => t.id.equals(id))).write(
      const OfflineTransactionsCompanion(
        retryCount: Value(0),
        lastError: Value(null),
        failedAt: Value(null),
      ),
    );
  }

  /// Permanently deletes an offline transaction from the local queue.
  Future<void> deleteOfflineTransaction(String id) async {
    await (_db.delete(
      _db.offlineTransactions,
    )..where((t) => t.id.equals(id))).go();
  }
}

final cacheServiceProvider = Provider<CacheService>((ref) {
  final db = ref.watch(databaseProvider);
  return CacheService(db);
});
