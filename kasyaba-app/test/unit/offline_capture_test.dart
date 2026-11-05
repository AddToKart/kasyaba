import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/connectivity/connectivity_service.dart';
import 'package:kasyaba/core/database/offline_sync_service.dart';
import 'package:kasyaba/core/providers/api_providers.dart';

import '../support/fake_engine_stack.dart';

const String _userId = 'qa-user';
const String _resolvedCategoryId = '11111111-1111-4111-8111-111111111111';

void main() {
  group('offline expense capture', () {
    late FakeEngineStack stack;

    setUp(() async {
      stack = await FakeEngineStack.create();
    });

    tearDown(() async {
      await stack.dispose();
    });

    test(
      'queues a non-UUID category offline and replays the resolved UUID',
      () async {
        stack.api.json('GET', '/expense-categories', {
          'data': [
            {
              'id': _resolvedCategoryId,
              'name': 'Food & Dining',
              'iconKey': 'restaurant',
            },
          ],
        });
        stack.setOnline(false);
        await _waitFor(() async => !stack.container.read(isOnlineProvider));

        final status = await stack.mutator.addExpense(
          accountId: 'acct-1',
          categoryId: 'cat_food',
          categoryName: 'Food & Dining',
          amount: 99.25,
          description: 'Offline lunch',
          spentAt: DateTime(2026, 11, 1),
        );

        expect(status, TransactionSaveStatus.queued);
        expect(stack.api.count('POST', '/expenses'), 0);

        final pending = await stack.cache.getPendingSyncTransactions(_userId);
        expect(pending, hasLength(1));
        final queued = jsonDecode(pending.single.json) as Map<String, dynamic>;
        expect(queued['categoryId'], 'cat_food');
        expect(queued['categoryName'], 'Food & Dining');
        expect(queued['clientMutationId'], isNotEmpty);

        final synced = await stack.cache.syncPendingTransactions(
          stack.dio,
          _userId,
        );
        expect(synced, 1);

        final post = stack.api.callsTo('POST', '/expenses').single;
        expect(post.bodyAsMap['categoryId'], _resolvedCategoryId);
        expect(post.bodyAsMap['categoryName'], 'Food & Dining');
        expect(await stack.cache.getPendingSyncTransactions(_userId), isEmpty);
      },
    );

    test(
      'online expense keeps the direct POST path and never queues',
      () async {
        final status = await stack.mutator.addExpense(
          accountId: 'acct-1',
          categoryId: _resolvedCategoryId,
          amount: 42,
          description: 'Online snack',
          spentAt: DateTime(2026, 11, 1),
        );

        expect(status, TransactionSaveStatus.saved);
        expect(stack.api.count('POST', '/expenses'), 1);
        expect(await stack.cache.getPendingSyncTransactions(_userId), isEmpty);
        expect(
          stack.api
              .callsTo('POST', '/expenses')
              .single
              .bodyAsMap['clientMutationId'],
          isNotEmpty,
        );
      },
    );

    test(
      'online expense with a legacy category id resolves before posting',
      () async {
        stack.api.json('GET', '/expense-categories', {
          'data': [
            {
              'id': _resolvedCategoryId,
              'name': 'Food & Dining',
              'iconKey': 'restaurant',
            },
          ],
        });

        final status = await stack.mutator.addExpense(
          accountId: 'acct-1',
          categoryId: 'cat_food',
          categoryName: 'Food & Dining',
          amount: 17.5,
          description: 'Resolved snack',
          spentAt: DateTime(2026, 11, 1),
        );

        expect(status, TransactionSaveStatus.saved);
        expect(await stack.cache.getPendingSyncTransactions(_userId), isEmpty);
        expect(
          stack.api.callsTo('POST', '/expenses').single.bodyAsMap['categoryId'],
          _resolvedCategoryId,
        );
      },
    );
  });

  group('offline goal contributions', () {
    late FakeEngineStack stack;

    setUp(() async {
      stack = await FakeEngineStack.create();
    });

    tearDown(() async {
      await stack.dispose();
    });

    test('queues, replays once with the same clientMutationId, and ignores '
        'the already-synced row on a second replay', () async {
      stack.api.on('POST', RegExp(r'^/goals/g1/contributions$'), (call) {
        throw DioException.connectionError(
          requestOptions: call.requestOptions,
          reason: 'qa offline',
        );
      });

      await stack.mutator.addGoalContribution(
        goalId: 'g1',
        amount: 250,
        accountId: 'acct-1',
        notes: 'Offline deposit',
      );

      final pending = await stack.cache.getPendingSyncTransactions(_userId);
      expect(pending, hasLength(1));
      expect(pending.single.type, 'goal_contribution');
      final queued = jsonDecode(pending.single.json) as Map<String, dynamic>;
      expect(queued['goalId'], 'g1');
      expect(queued['amount'], '250.00');
      expect(queued['contributedAt'], endsWith('Z'));
      final mutationId = queued['clientMutationId'];
      expect(mutationId, isNotEmpty);

      stack.api.json('POST', RegExp(r'^/goals/g1/contributions$'), {
        'data': <String, dynamic>{},
      });

      final synced = await stack.cache.syncPendingTransactions(
        stack.dio,
        _userId,
      );
      expect(synced, 1);

      final post = stack.api.callsTo('POST', '/goals/g1/contributions').last;
      expect(post.bodyAsMap, isNot(contains('goalId')));
      expect(post.bodyAsMap['clientMutationId'], mutationId);
      expect(post.bodyAsMap['amount'], '250.00');

      final callsAfterFirstReplay = stack.api
          .callsTo('POST', '/goals/g1/contributions')
          .length;
      final secondReplay = await stack.cache.syncPendingTransactions(
        stack.dio,
        _userId,
      );
      expect(secondReplay, 0);
      expect(
        stack.api.callsTo('POST', '/goals/g1/contributions').length,
        callsAfterFirstReplay,
      );
      expect(await stack.cache.getAllOfflineTransactions(_userId), isEmpty);
    });
  });

  group('offline replay refresh', () {
    late FakeEngineStack stack;

    setUp(() async {
      stack = await FakeEngineStack.create();
    });

    tearDown(() async {
      await stack.dispose();
    });

    test(
      'a successful replay invalidates the full finance provider set',
      () async {
        final probes = <ProviderProbe>[
          stack.probe('dashboard', dashboardProvider),
          stack.probe('paginated', paginatedTransactionsProvider),
          stack.probe('transactions', transactionsProvider),
          stack.probe('alerts', alertsProvider),
          stack.probe('accounts', accountsProvider),
          stack.probe('balances', accountBalancesProvider),
          stack.probe('planning', planningProvider),
          stack.probe('budgetStatus', budgetStatusProvider),
          stack.probe('goals', goalsProvider),
          stack.probe('bills', billsProvider),
          stack.probe('userProfile', userProfileProvider),
          stack.probeAutoDispose('goalDetail(g1)', goalDetailProvider('g1')),
        ];
        await stack.warm(probes);
        final before = stack.emissionsSnapshot(probes);

        await stack.cache.seedTransaction(
          id: 'replay-refresh-1',
          type: 'expense',
          userId: _userId,
          data: {
            'accountId': 'acct-1',
            'categoryId': _resolvedCategoryId,
            'amount': '15.00',
            'description': 'Replayed',
            'spentAt': '2026-11-01',
            'status': 'posted',
            'clientMutationId': 'replay-refresh-mutation',
          },
          createdAt: DateTime(2026, 11, 1),
        );

        stack.container.read(offlineSyncProvider);
        await _waitFor(
          () async =>
              (await stack.cache.getPendingSyncTransactions(_userId)).isEmpty,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await stack.warm(probes);
        final refreshed = probes
            .where((probe) => probe.emissions > (before[probe] ?? 0))
            .length;
        expect(
          refreshed,
          greaterThanOrEqualTo(9),
          reason:
              'A replay must refresh balances, planning, budgets, goals, '
              'bills and alerts too.',
        );
        expect(stack.api.count('POST', '/expenses'), 1);
      },
    );
  });
}

Future<void> _waitFor(Future<bool> Function() condition) async {
  for (var attempt = 0; attempt < 400; attempt++) {
    if (await condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met within the test timeout.');
}
