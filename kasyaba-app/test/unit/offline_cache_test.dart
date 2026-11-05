import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/database/cache_service.dart';
import 'package:kasyaba/core/database/database.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/providers/session_refresh_provider.dart';

import '../support/fake_engine_stack.dart';

const String _userId = 'qa-user';

DashboardData _cachedDashboard() => const DashboardData(
  totalBalance: 1000,
  income: 500,
  expenses: 250,
  savings: 100,
  healthScore: 'Good',
  predictedMonthEnd: 900,
  budgetUsedPercent: 10,
  categoryExpenses: <CategoryExpenseSummary>[],
  dailyBalance: <DailyBalancePoint>[],
);

DateTime _seconds(DateTime value) =>
    DateTime.fromMillisecondsSinceEpoch(value.millisecondsSinceEpoch);

void main() {
  group('CacheService snapshot store', () {
    late AppDatabase database;
    late CacheService cache;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      cache = CacheService(database);
    });

    tearDown(() => database.close());

    test('putSnapshot/getSnapshot round-trips json and fetchedAt', () async {
      final fetchedAt = DateTime(2026, 11, 1, 9, 30);
      await cache.putSnapshot(
        userId: _userId,
        key: CacheService.snapshotKeyAccounts,
        json: jsonEncode([
          {'id': 'acct-1', 'name': 'Cash', 'type': 'cash'},
        ]),
        fetchedAt: fetchedAt,
      );

      final snapshot = await cache.getSnapshot(
        _userId,
        CacheService.snapshotKeyAccounts,
      );
      expect(snapshot, isNotNull);
      expect(jsonDecode(snapshot!.json), [
        {'id': 'acct-1', 'name': 'Cash', 'type': 'cash'},
      ]);
      expect(
        snapshot.fetchedAt.millisecondsSinceEpoch,
        fetchedAt.millisecondsSinceEpoch,
      );
      expect(
        await cache.getSnapshot(
          'another-user',
          CacheService.snapshotKeyAccounts,
        ),
        isNull,
      );
    });

    test('snapshots are isolated per user', () async {
      await cache.putSnapshot(
        userId: _userId,
        key: CacheService.snapshotKeyDashboard,
        json: '{"owner":"qa"}',
      );
      await cache.putSnapshot(
        userId: 'other-user',
        key: CacheService.snapshotKeyDashboard,
        json: '{"owner":"other"}',
      );

      expect(
        (await cache.getSnapshot(
          _userId,
          CacheService.snapshotKeyDashboard,
        ))!.json,
        '{"owner":"qa"}',
      );
      expect(
        (await cache.getSnapshot(
          'other-user',
          CacheService.snapshotKeyDashboard,
        ))!.json,
        '{"owner":"other"}',
      );
    });

    test('transaction snapshots prune to the 10 newest views only', () async {
      for (var index = 0; index < 12; index++) {
        await cache.putSnapshot(
          userId: _userId,
          key: CacheService.transactionsKey(page: index + 1),
          json: '{"page":${index + 1}}',
          fetchedAt: DateTime(2026, 11, 1).add(Duration(minutes: index)),
        );
      }
      await cache.putSnapshot(
        userId: _userId,
        key: CacheService.snapshotKeyBills,
        json: '[]',
        fetchedAt: DateTime(2026, 1, 1),
      );

      final transactionSnapshots =
          await (database.select(database.cachedSnapshots)..where(
                (t) => t.userId.equals(_userId) & t.key.like('transactions:%'),
              ))
              .get();
      expect(transactionSnapshots, hasLength(10));
      expect(
        transactionSnapshots.map((row) => row.key),
        isNot(contains(CacheService.transactionsKey(page: 1))),
      );
      expect(
        transactionSnapshots.map((row) => row.key),
        contains(CacheService.transactionsKey(page: 12)),
      );
      // Non-transaction snapshots are never pruned by the transaction cap.
      expect(
        await cache.getSnapshot(_userId, CacheService.snapshotKeyBills),
        isNotNull,
      );
    });

    test(
      'deleteSnapshotsFor keeps the queue; deleteAllForUser clears both',
      () async {
        await cache.putSnapshot(
          userId: _userId,
          key: CacheService.snapshotKeyGoals,
          json: '[]',
        );
        await cache.queueTransaction(
          type: 'expense',
          userId: _userId,
          data: {'amount': '10.00', 'categoryId': 'cat_food'},
        );

        await cache.deleteSnapshotsFor(_userId);
        expect(
          await cache.getSnapshot(_userId, CacheService.snapshotKeyGoals),
          isNull,
        );
        expect(await cache.getPendingSyncTransactions(_userId), hasLength(1));

        await cache.deleteAllForUser(_userId);
        expect(await cache.getAllOfflineTransactions(_userId), isEmpty);
      },
    );
  });

  group('provider snapshot fallbacks', () {
    late FakeEngineStack stack;

    setUp(() async {
      stack = await FakeEngineStack.create();
    });

    tearDown(() async {
      await stack.dispose();
    });

    test('dashboard failure serves snapshot with pending overlay', () async {
      final cached = _cachedDashboard();
      await stack.cache.putSnapshot(
        userId: _userId,
        key: CacheService.snapshotKeyDashboard,
        json: jsonEncode(cached.toJson()),
        fetchedAt: DateTime(2026, 11, 1),
      );
      await stack.cache.seedTransaction(
        id: 'offline-dashboard-1',
        type: 'expense',
        userId: _userId,
        data: {'amount': '125.00', 'description': 'Offline coffee'},
      );

      stack.api.on('GET', '/dashboard', (call) {
        throw DioException.connectionError(
          requestOptions: call.requestOptions,
          reason: 'qa offline',
        );
      });

      final dashboard = await stack.container.read(dashboardProvider.future);
      expect(dashboard.isFromCache, isTrue);
      expect(dashboard.totalBalance, 875);
      expect(dashboard.expenses, 375);
      expect(dashboard.income, 500);
    });

    test(
      'transactions fall back to the cached view for the same filter key',
      () async {
        final from = DateTime(2026, 11, 1);
        final to = DateTime(2026, 11, 30);
        final cachedEntry = TransactionEntry(
          id: 'server-1',
          title: 'Cached transaction',
          amount: 10,
          isExpense: true,
          date: DateTime(2026, 11, 5),
          categoryName: 'Food',
        );
        await stack.cache.putSnapshot(
          userId: _userId,
          key: CacheService.transactionsKey(page: 1, from: from, to: to),
          json: jsonEncode({
            'items': [cachedEntry.toJson()],
            'totalCount': 1,
          }),
          fetchedAt: DateTime(2026, 11, 1),
        );
        await stack.cache.seedTransaction(
          id: 'pending-in-range',
          type: 'expense',
          userId: _userId,
          data: {'amount': '5.00', 'spentAt': '2026-11-02'},
          createdAt: DateTime(2026, 11, 2),
        );
        await stack.cache.seedTransaction(
          id: 'pending-out-of-range',
          type: 'expense',
          userId: _userId,
          data: {'amount': '7.00', 'spentAt': '2026-10-02'},
          createdAt: DateTime(2026, 10, 2),
        );
        stack.container
            .read(transactionFilterProvider.notifier)
            .state = TransactionQueryFilter(
          page: 1,
          limit: 50,
          fromDate: from,
          toDate: to,
        );
        stack.api.on('GET', '/transactions', (call) {
          throw DioException.connectionError(
            requestOptions: call.requestOptions,
            reason: 'qa offline',
          );
        });

        final page = await stack.container.read(
          paginatedTransactionsProvider.future,
        );
        expect(page.items.map((entry) => entry.id), [
          'pending-in-range',
          'server-1',
        ]);
        expect(page.totalCount, 2);
      },
    );

    test('cachedSnapshotMetaProvider exposes the snapshot fetchedAt', () async {
      final fetchedAt = DateTime(2026, 11, 2, 8, 15);
      await stack.cache.putSnapshot(
        userId: _userId,
        key: CacheService.snapshotKeyBills,
        json: '[]',
        fetchedAt: fetchedAt,
      );

      final meta = await stack.container.read(
        cachedSnapshotMetaProvider(CacheService.snapshotKeyBills).future,
      );
      expect(meta, fetchedAt);
      expect(
        await stack.container.read(
          cachedSnapshotMetaProvider(CacheService.snapshotKeyAlerts).future,
        ),
        isNull,
      );
    });

    test('sign-out clears snapshots but keeps the offline queue', () async {
      stack.container.read(sessionDataResetProvider);
      await stack.cache.putSnapshot(
        userId: _userId,
        key: CacheService.snapshotKeyAccounts,
        json: '[]',
      );
      await stack.cache.seedTransaction(
        id: 'offline-signout-1',
        type: 'expense',
        userId: _userId,
        data: {'amount': '20.00', 'categoryId': 'cat_food'},
      );

      await stack.container.read(authProvider.notifier).logout();
      await _waitFor(
        () async =>
            await stack.cache.getSnapshot(
              _userId,
              CacheService.snapshotKeyAccounts,
            ) ==
            null,
      );

      expect(
        await stack.cache.getSnapshot(
          _userId,
          CacheService.snapshotKeyAccounts,
        ),
        isNull,
      );
      expect(
        await stack.cache.getPendingSyncTransactions(_userId),
        hasLength(1),
      );
    });
  });

  group('schema migration v3 -> v4', () {
    test(
      'migrates the legacy dashboard row and preserves queued rows',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'kasyaba_migration_',
        );
        final file = File('${directory.path}/legacy.db');
        addTearDown(() async {
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
        });

        final fetchedAt = DateTime(2026, 11, 1, 12, 30);
        final dashboardJson = {
          'balance': '42.00',
          'income': '7.00',
          'expenses': '3.00',
          'savings': '1.00',
          'healthGrade': 'Good',
          'predictedMonthEndBalance': '39.00',
          'charts': {
            'expensesByCategory': <dynamic>[],
            'dailyBalance': <dynamic>[],
          },
        };

        final legacy = NativeDatabase(file);
        await legacy.ensureOpen(_LegacyExecutorUser());
        await legacy.runCustom(
          'CREATE TABLE cached_dashboard ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'json TEXT NOT NULL, '
          'updated_at INTEGER NOT NULL)',
        );
        await legacy.runCustom(
          'CREATE TABLE offline_transactions ('
          'id TEXT NOT NULL PRIMARY KEY, '
          'user_id TEXT NULL, '
          'type TEXT NOT NULL, '
          'json TEXT NOT NULL, '
          'created_at INTEGER NOT NULL, '
          'synced_at INTEGER NULL, '
          'retry_count INTEGER NOT NULL DEFAULT 0, '
          'last_error TEXT NULL, '
          'failed_at INTEGER NULL)',
        );
        await legacy.runCustom(
          'INSERT INTO cached_dashboard (json, updated_at) VALUES (?, ?)',
          [
            jsonEncode({'userId': 'legacy-user', 'data': dashboardJson}),
            fetchedAt.millisecondsSinceEpoch ~/ 1000,
          ],
        );
        await legacy.runCustom(
          'INSERT INTO offline_transactions '
          '(id, user_id, type, json, created_at, retry_count) '
          'VALUES (?, ?, ?, ?, ?, ?)',
          [
            'legacy-queue-1',
            'legacy-user',
            'expense',
            jsonEncode({'amount': '12.00', 'categoryId': 'cat_food'}),
            fetchedAt.millisecondsSinceEpoch ~/ 1000,
            0,
          ],
        );
        await legacy.runCustom('PRAGMA user_version = 3');
        await legacy.close();

        final database = AppDatabase(NativeDatabase(file));
        addTearDown(database.close);
        final cache = CacheService(database);

        final snapshot = await cache.getSnapshot('legacy-user', 'dashboard');
        expect(snapshot, isNotNull);
        expect(jsonDecode(snapshot!.json), dashboardJson);
        expect(
          _seconds(snapshot.fetchedAt).millisecondsSinceEpoch,
          _seconds(fetchedAt).millisecondsSinceEpoch,
        );

        final legacyTable = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name = 'cached_dashboard'",
            )
            .get();
        expect(legacyTable, isEmpty);

        final queued = await cache.getPendingSyncTransactions('legacy-user');
        expect(queued, hasLength(1));
        expect(queued.single.id, 'legacy-queue-1');
      },
    );
  });
}

class _LegacyExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 3;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

Future<void> _waitFor(Future<bool> Function() condition) async {
  for (var attempt = 0; attempt < 400; attempt++) {
    if (await condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met within the test timeout.');
}
