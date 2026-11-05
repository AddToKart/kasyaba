import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';

import '../support/fake_engine_stack.dart';

const String _categoryId = '11111111-1111-4111-8111-111111111111';
const String _userId = 'qa-user';
final DateTime _postedDate = DateTime(2026, 1, 5);

typedef _MutationRunner = Future<void> Function(TransactionMutator mutator);

const Map<String, int> _fullHubEndpoints = <String, int>{
  'GET /dashboard': 1,
  'GET /transactions': 1,
  'GET /alerts': 1,
  'GET /accounts': 1,
  'GET /accounts/acct-1/balance': 1,
  'GET /planning/overview': 1,
  'GET /budgets/status': 1,
  'GET /goals': 1,
  'GET /bills': 1,
  'GET /auth/me': 0,
  'GET /expense-categories': 0,
  'GET /goals/g1': 0,
  'GET /goals/g2': 0,
};

void main() {
  group('mutation invalidation matrix', () {
    late FakeEngineStack stack;
    late TransactionMutator mutator;
    late ProviderProbe dashboard;
    late ProviderProbe paginated;
    late ProviderProbe transactions;
    late ProviderProbe alerts;
    late ProviderProbe accounts;
    late ProviderProbe balances;
    late ProviderProbe planning;
    late ProviderProbe budgetStatus;
    late ProviderProbe goals;
    late ProviderProbe bills;
    late ProviderProbe userProfile;
    late ProviderProbe categories;
    late ProviderProbe goalOne;
    late ProviderProbe goalTwo;
    late List<ProviderProbe> allProbes;

    setUp(() async {
      stack = await FakeEngineStack.create();
      mutator = stack.mutator;

      dashboard = stack.probe('dashboard', dashboardProvider);
      paginated = stack.probe(
        'paginatedTransactions',
        paginatedTransactionsProvider,
      );
      transactions = stack.probe('transactions', transactionsProvider);
      alerts = stack.probe('alerts', alertsProvider);
      accounts = stack.probe('accounts', accountsProvider);
      balances = stack.probe('accountBalances', accountBalancesProvider);
      planning = stack.probe('planning', planningProvider);
      budgetStatus = stack.probe('budgetStatus', budgetStatusProvider);
      goals = stack.probe('goals', goalsProvider);
      bills = stack.probe('bills', billsProvider);
      userProfile = stack.probe('userProfile', userProfileProvider);
      categories = stack.probe('categories', categoriesProvider);
      goalOne = stack.probeAutoDispose(
        'goalDetail(g1)',
        goalDetailProvider('g1'),
      );
      goalTwo = stack.probeAutoDispose(
        'goalDetail(g2)',
        goalDetailProvider('g2'),
      );

      allProbes = [
        accounts,
        balances,
        dashboard,
        paginated,
        transactions,
        alerts,
        planning,
        budgetStatus,
        goals,
        bills,
        userProfile,
        categories,
        goalOne,
        goalTwo,
      ];
      await stack.warm(allProbes);
    });

    tearDown(() async {
      await stack.dispose();
    });

    test(
      'addExpense refetches the full transaction hub exactly once',
      () async {
        await _expectHubRefresh(
          stack,
          mutator,
          allProbes,
          (m) async {
            await m.addExpense(
              accountId: 'acct-1',
              categoryId: _categoryId,
              amount: 125.50,
              description: 'QA expense',
              spentAt: _postedDate,
            );
          },
          [
            dashboard,
            paginated,
            transactions,
            alerts,
            accounts,
            balances,
            planning,
            budgetStatus,
            goals,
            bills,
          ],
          [userProfile, categories, goalOne, goalTwo],
        );
      },
    );

    test('addIncome refetches the full transaction hub exactly once', () async {
      await _expectHubRefresh(
        stack,
        mutator,
        allProbes,
        (m) async {
          await m.addIncome(
            accountId: 'acct-1',
            amount: 2500,
            source: 'QA salary',
            receivedAt: _postedDate,
          );
        },
        [
          dashboard,
          paginated,
          transactions,
          alerts,
          accounts,
          balances,
          planning,
          budgetStatus,
          goals,
          bills,
        ],
        [userProfile, categories, goalOne, goalTwo],
      );
    });

    test(
      'updateExpense refetches the full transaction hub exactly once',
      () async {
        await _expectHubRefresh(
          stack,
          mutator,
          allProbes,
          (m) async {
            await m.updateExpense(
              id: 'expense-1',
              accountId: 'acct-1',
              categoryId: _categoryId,
              amount: 200,
              description: 'QA expense edited',
              spentAt: _postedDate,
            );
          },
          [
            dashboard,
            paginated,
            transactions,
            alerts,
            accounts,
            balances,
            planning,
            budgetStatus,
            goals,
            bills,
          ],
          [userProfile, categories, goalOne, goalTwo],
        );
      },
    );

    test(
      'updateIncome refetches the full transaction hub exactly once',
      () async {
        await _expectHubRefresh(
          stack,
          mutator,
          allProbes,
          (m) async {
            await m.updateIncome(
              id: 'income-1',
              accountId: 'acct-1',
              amount: 2600,
              source: 'QA salary edited',
              receivedAt: _postedDate,
            );
          },
          [
            dashboard,
            paginated,
            transactions,
            alerts,
            accounts,
            balances,
            planning,
            budgetStatus,
            goals,
            bills,
          ],
          [userProfile, categories, goalOne, goalTwo],
        );
      },
    );

    test(
      'deleteTransaction refetches the full transaction hub exactly once',
      () async {
        await _expectHubRefresh(
          stack,
          mutator,
          allProbes,
          (m) async {
            await m.deleteTransaction(
              TransactionEntry(
                id: 'expense-1',
                title: 'QA expense',
                amount: 125.50,
                isExpense: true,
                date: _postedDate,
                categoryName: 'Other',
              ),
            );
          },
          [
            dashboard,
            paginated,
            transactions,
            alerts,
            accounts,
            balances,
            planning,
            budgetStatus,
            goals,
            bills,
          ],
          [userProfile, categories, goalOne, goalTwo],
        );
      },
    );

    test(
      'addTransfer refetches the full transaction hub exactly once',
      () async {
        await _expectHubRefresh(
          stack,
          mutator,
          allProbes,
          (m) async {
            await m.addTransfer(
              fromAccountId: 'acct-1',
              toAccountId: 'acct-2',
              amount: 300,
              transferredAt: _postedDate,
            );
          },
          [
            dashboard,
            paginated,
            transactions,
            alerts,
            accounts,
            balances,
            planning,
            budgetStatus,
            goals,
            bills,
          ],
          [userProfile, categories, goalOne, goalTwo],
        );
      },
    );

    test(
      'addGoalContribution refetches only its goal detail and contribution hub',
      () async {
        await _expectHubRefresh(
          stack,
          mutator,
          allProbes,
          (m) async {
            await m.addGoalContribution(
              goalId: 'g1',
              amount: 250,
              accountId: 'acct-1',
            );
          },
          [
            goals,
            dashboard,
            accounts,
            balances,
            paginated,
            transactions,
            planning,
            alerts,
            goalOne,
          ],
          [bills, budgetStatus, userProfile, categories, goalTwo],
          endpoints: const {
            'GET /goals': 1,
            'GET /dashboard': 1,
            'GET /accounts': 1,
            'GET /accounts/acct-1/balance': 1,
            'GET /transactions': 1,
            'GET /planning/overview': 1,
            'GET /alerts': 1,
            'GET /goals/g1': 1,
            'GET /goals/g2': 0,
            'GET /bills': 0,
            'GET /budgets/status': 0,
            'GET /auth/me': 0,
            'GET /expense-categories': 0,
          },
        );
      },
    );

    test(
      'addGoal parses the POST response and refetches goals/dashboard/planning/alerts',
      () async {
        stack.api.json('POST', '/goals', {
          'data': {
            'id': 'goal-vacation',
            'name': 'Vacation',
            'targetAmount': '15000.00',
            'currentAmount': '0.00',
          },
        });

        final emissionsBefore = stack.emissionsSnapshot(allProbes);
        final endpointsBefore = stack.api.snapshot();

        final created = await mutator.addGoal(
          name: 'Vacation',
          targetAmount: 15000,
        );

        expect(created, isNotNull);
        expect(created!.id, 'goal-vacation');
        expect(created.name, 'Vacation');
        expect(created.targetAmount, 15000);
        expect(created.currentAmount, 0);

        await stack.warm(allProbes);
        final endpointsAfter = stack.api.snapshot();

        _expectRefreshed([goals, dashboard, planning, alerts], emissionsBefore);
        _expectUntouched([
          accounts,
          balances,
          paginated,
          transactions,
          bills,
          budgetStatus,
          userProfile,
          categories,
          goalOne,
          goalTwo,
        ], emissionsBefore);
        _expectEndpoints(endpointsBefore, endpointsAfter, const {
          'GET /goals': 1,
          'GET /dashboard': 1,
          'GET /planning/overview': 1,
          'GET /alerts': 1,
          'GET /accounts': 0,
          'GET /accounts/acct-1/balance': 0,
          'GET /transactions': 0,
          'GET /bills': 0,
          'GET /budgets/status': 0,
          'GET /auth/me': 0,
          'GET /expense-categories': 0,
          'GET /goals/g1': 0,
          'GET /goals/g2': 0,
        });
      },
    );

    test('updateGoal refetches the edited goal detail', () async {
      await _expectHubRefresh(
        stack,
        mutator,
        allProbes,
        (m) async {
          await m.updateGoal(
            goalId: 'g1',
            name: 'Updated goal',
            targetAmount: 2000,
          );
        },
        [goals, dashboard, planning, alerts, goalOne],
        [
          accounts,
          balances,
          paginated,
          transactions,
          bills,
          budgetStatus,
          userProfile,
          categories,
          goalTwo,
        ],
        endpoints: const {
          'GET /goals': 1,
          'GET /dashboard': 1,
          'GET /planning/overview': 1,
          'GET /alerts': 1,
          'GET /goals/g1': 1,
          'GET /goals/g2': 0,
          'GET /accounts': 0,
          'GET /accounts/acct-1/balance': 0,
          'GET /transactions': 0,
          'GET /bills': 0,
          'GET /budgets/status': 0,
          'GET /auth/me': 0,
          'GET /expense-categories': 0,
        },
      );
    });

    test('deleteGoal refetches the deleted goal detail', () async {
      await _expectHubRefresh(
        stack,
        mutator,
        allProbes,
        (m) async {
          await m.deleteGoal('g1');
        },
        [goals, dashboard, planning, alerts, goalOne],
        [
          accounts,
          balances,
          paginated,
          transactions,
          bills,
          budgetStatus,
          userProfile,
          categories,
          goalTwo,
        ],
        endpoints: const {
          'GET /goals': 1,
          'GET /dashboard': 1,
          'GET /planning/overview': 1,
          'GET /alerts': 1,
          'GET /goals/g1': 1,
          'GET /goals/g2': 0,
          'GET /accounts': 0,
          'GET /accounts/acct-1/balance': 0,
          'GET /transactions': 0,
          'GET /bills': 0,
          'GET /budgets/status': 0,
          'GET /auth/me': 0,
          'GET /expense-categories': 0,
        },
      );
    });

    test('markBillPaid refetches the full bill/transaction hub', () async {
      await _expectHubRefresh(
        stack,
        mutator,
        allProbes,
        (m) async {
          await m.markBillPaid(billId: 'bill-1', accountId: 'acct-1');
        },
        [
          bills,
          dashboard,
          accounts,
          balances,
          paginated,
          transactions,
          planning,
          budgetStatus,
          goals,
          alerts,
        ],
        [userProfile, categories, goalOne, goalTwo],
        endpoints: _fullHubEndpoints,
      );
    });

    test('markBillUnpaid refetches the full bill/transaction hub', () async {
      await _expectHubRefresh(
        stack,
        mutator,
        allProbes,
        (m) async {
          await m.markBillUnpaid('bill-1');
        },
        [
          bills,
          dashboard,
          accounts,
          balances,
          paginated,
          transactions,
          planning,
          budgetStatus,
          goals,
          alerts,
        ],
        [userProfile, categories, goalOne, goalTwo],
        endpoints: _fullHubEndpoints,
      );
    });

    test(
      'updateProfile refetches profile/dashboard/planning/alerts and sends only supplied fields',
      () async {
        final emissionsBefore = stack.emissionsSnapshot(allProbes);
        final endpointsBefore = stack.api.snapshot();

        await mutator.updateProfile(
          salaryAmount: 45000,
          paydayFrequency: 'semi-monthly',
          paydaySchedule: '15th & 30th',
        );

        final patch = stack.api.callsTo('PATCH', '/auth/me').single;
        expect(patch.bodyAsMap, isNot(contains('minimumBalanceThreshold')));
        expect(patch.bodyAsMap, isNot(contains('displayName')));
        expect(
          patch.bodyAsMap,
          equals({
            'salaryAmount': '45000.00',
            'paydayFrequency': 'semi-monthly',
            'paydaySchedule': '15th & 30th',
          }),
        );

        await stack.warm(allProbes);
        final endpointsAfter = stack.api.snapshot();

        _expectRefreshed([
          userProfile,
          dashboard,
          planning,
          alerts,
        ], emissionsBefore);
        _expectUntouched([
          accounts,
          balances,
          paginated,
          transactions,
          bills,
          budgetStatus,
          goals,
          categories,
          goalOne,
          goalTwo,
        ], emissionsBefore);
        _expectEndpoints(endpointsBefore, endpointsAfter, const {
          'GET /auth/me': 1,
          'GET /dashboard': 1,
          'GET /planning/overview': 1,
          'GET /alerts': 1,
          'GET /accounts': 0,
          'GET /accounts/acct-1/balance': 0,
          'GET /transactions': 0,
          'GET /bills': 0,
          'GET /budgets/status': 0,
          'GET /goals': 0,
          'GET /expense-categories': 0,
          'GET /goals/g1': 0,
          'GET /goals/g2': 0,
        });
      },
    );

    test(
      'createAccount refetches accounts/balances/dashboard/planning/alerts',
      () async {
        await _expectAccountRefresh(
          stack,
          allProbes,
          (m) async {
            await m.createAccount(
              name: 'QA Savings',
              type: 'savings',
              openingBalance: 100,
            );
          },
          [accounts, balances, dashboard, planning, alerts],
          [
            paginated,
            transactions,
            bills,
            budgetStatus,
            goals,
            userProfile,
            categories,
            goalOne,
            goalTwo,
          ],
        );
      },
    );

    test(
      'archiveAccount refetches accounts/balances/dashboard/planning/alerts',
      () async {
        await _expectAccountRefresh(
          stack,
          allProbes,
          (m) async {
            await m.archiveAccount('acct-1');
          },
          [accounts, balances, dashboard, planning, alerts],
          [
            paginated,
            transactions,
            bills,
            budgetStatus,
            goals,
            userProfile,
            categories,
            goalOne,
            goalTwo,
          ],
        );
      },
    );

    test(
      'createBudget sends startsOn/amount/categoryId and refetches budget status',
      () async {
        final emissionsBefore = stack.emissionsSnapshot(allProbes);
        final endpointsBefore = stack.api.snapshot();

        await mutator.createBudget(
          amount: 5000,
          startsOn: DateTime(2026, 11, 1),
          categoryId: 'cat-food',
        );

        final post = stack.api.callsTo('POST', '/budgets').single;
        expect(
          post.bodyAsMap,
          equals({
            'amount': '5000.00',
            'startsOn': '2026-11-01',
            'categoryId': 'cat-food',
            'isActive': true,
          }),
        );

        await stack.warm(allProbes);
        final endpointsAfter = stack.api.snapshot();

        _expectRefreshed([budgetStatus, dashboard, alerts], emissionsBefore);
        _expectUntouched([
          accounts,
          balances,
          paginated,
          transactions,
          bills,
          goals,
          planning,
          userProfile,
          categories,
          goalOne,
          goalTwo,
        ], emissionsBefore);
        _expectEndpoints(endpointsBefore, endpointsAfter, const {
          'GET /budgets/status': 1,
          'GET /dashboard': 1,
          'GET /alerts': 1,
          'GET /accounts': 0,
          'GET /accounts/acct-1/balance': 0,
          'GET /transactions': 0,
          'GET /bills': 0,
          'GET /goals': 0,
          'GET /planning/overview': 0,
          'GET /auth/me': 0,
          'GET /expense-categories': 0,
          'GET /goals/g1': 0,
          'GET /goals/g2': 0,
        });
      },
    );

    test('createBudget omits categoryId when one was not supplied', () async {
      await mutator.createBudget(amount: 1000, startsOn: DateTime(2026, 12, 1));

      final post = stack.api.callsTo('POST', '/budgets').single;
      expect(
        post.bodyAsMap,
        equals({
          'amount': '1000.00',
          'startsOn': '2026-12-01',
          'isActive': true,
        }),
      );
    });

    test('deleteBudget refetches budget status/dashboard/alerts', () async {
      final emissionsBefore = stack.emissionsSnapshot(allProbes);
      final endpointsBefore = stack.api.snapshot();

      await mutator.deleteBudget('budget-1');

      expect(stack.api.count('DELETE', '/budgets/budget-1'), 1);

      await stack.warm(allProbes);
      final endpointsAfter = stack.api.snapshot();

      _expectRefreshed([budgetStatus, dashboard, alerts], emissionsBefore);
      _expectUntouched([
        accounts,
        balances,
        paginated,
        transactions,
        bills,
        goals,
        planning,
        userProfile,
        categories,
        goalOne,
        goalTwo,
      ], emissionsBefore);
      _expectEndpoints(endpointsBefore, endpointsAfter, const {
        'GET /budgets/status': 1,
        'GET /dashboard': 1,
        'GET /alerts': 1,
        'GET /accounts': 0,
        'GET /accounts/acct-1/balance': 0,
        'GET /transactions': 0,
        'GET /bills': 0,
        'GET /goals': 0,
        'GET /planning/overview': 0,
        'GET /auth/me': 0,
        'GET /expense-categories': 0,
        'GET /goals/g1': 0,
        'GET /goals/g2': 0,
      });
    });
  });

  group('mutation payload fidelity', () {
    late FakeEngineStack stack;
    late TransactionMutator mutator;

    setUp(() async {
      stack = await FakeEngineStack.create();
      mutator = stack.mutator;
    });

    tearDown(() async {
      await stack.dispose();
    });

    test(
      'addBill sends name/defaultAmount/startsOn/recurrence and default reminderLeadDays',
      () async {
        await mutator.addBill(
          name: 'Rent',
          amount: 1500,
          startsOn: DateTime(2026, 11, 5),
        );

        final call = stack.api.callsTo('POST', '/bill-templates').single;
        expect(
          call.bodyAsMap,
          equals({
            'name': 'Rent',
            'defaultAmount': '1500.00',
            'startsOn': '2026-11-05',
            'recurrence': 'monthly',
            'dayOfMonth': 5,
            'reminderLeadDays': 1,
          }),
        );
        expect(call.bodyAsMap, isNot(contains('categoryId')));
      },
    );

    test(
      'addBill includes categoryId and custom reminderLeadDays when supplied',
      () async {
        await mutator.addBill(
          name: 'Internet',
          amount: 1299.50,
          startsOn: DateTime(2026, 11, 6),
          recurrence: 'weekly',
          categoryId: 'cat-utilities',
          reminderLeadDays: 3,
        );

        final call = stack.api.callsTo('POST', '/bill-templates').single;
        expect(
          call.bodyAsMap,
          equals({
            'name': 'Internet',
            'defaultAmount': '1299.50',
            'startsOn': '2026-11-06',
            'recurrence': 'weekly',
            'dayOfWeek': 5,
            'categoryId': 'cat-utilities',
            'reminderLeadDays': 3,
          }),
        );
      },
    );

    test(
      'addBill refetches bills/dashboard/planning/alerts but not goals',
      () async {
        final alerts = stack.probe('alerts', alertsProvider);
        final bills = stack.probe('bills', billsProvider);
        final dashboard = stack.probe('dashboard', dashboardProvider);
        final planning = stack.probe('planning', planningProvider);
        final goals = stack.probe('goals', goalsProvider);
        final probes = [alerts, bills, dashboard, planning, goals];

        await stack.warm(probes);
        final emissionsBefore = stack.emissionsSnapshot(probes);

        await mutator.addBill(
          name: 'Water',
          amount: 800,
          startsOn: DateTime(2026, 11, 8),
        );

        await stack.warm(probes);
        final emissionsAfter = stack.emissionsSnapshot(probes);

        for (final probe in [alerts, bills, dashboard, planning]) {
          expect(
            emissionsAfter[probe],
            greaterThan(emissionsBefore[probe] ?? 0),
            reason: '${probe.name} should refetch after addBill',
          );
        }
        expect(
          emissionsAfter[goals],
          emissionsBefore[goals],
          reason: 'goals should not refetch after addBill',
        );
      },
    );

    test(
      'evaluatePurchaseCheck parses every PurchaseCheckResult field',
      () async {
        stack.api.json('POST', '/forecasting/purchase-check', {
          'data': {
            'itemTitle': 'Mechanical Keyboard',
            'amount': '4999.50',
            'verdict': 'STRETCH',
            'statusTitle': 'Wait a little',
            'statusMessage': 'This purchase delays one goal.',
            'currentBalance': '25000.00',
            'postPurchaseBalance': '20000.50',
            'projectedMonthEndBalance': '18000.00',
            'postPurchaseMonthEndBalance': '13000.50',
            'totalUpcomingBills': '4500.00',
            'cashAfterBills': '15500.50',
            'earliestSafeBuyDate': '2026-12-15',
            'daysUntilSafeBuy': 29,
            'reasons': ['Budget usage is high', 'Payday is far'],
            'goalImpacts': [
              {
                'goalName': 'Emergency Fund',
                'originalTargetDate': '2026-12-31',
                'delayedTargetDate': '2027-01-20',
                'delayDays': 20,
              },
            ],
          },
        });

        final result = await mutator.evaluatePurchaseCheck(
          itemTitle: 'Mechanical Keyboard',
          amount: 4999.5,
        );

        expect(result.itemTitle, 'Mechanical Keyboard');
        expect(result.amount, 4999.5);
        expect(result.verdict, 'STRETCH');
        expect(result.statusTitle, 'Wait a little');
        expect(result.statusMessage, 'This purchase delays one goal.');
        expect(result.currentBalance, 25000);
        expect(result.postPurchaseBalance, 20000.50);
        expect(result.projectedMonthEndBalance, 18000);
        expect(result.postPurchaseMonthEndBalance, 13000.50);
        expect(result.totalUpcomingBills, 4500);
        expect(result.cashAfterBills, 15500.50);
        expect(result.earliestSafeBuyDate, '2026-12-15');
        expect(result.daysUntilSafeBuy, 29);
        expect(result.reasons, ['Budget usage is high', 'Payday is far']);
        expect(result.goalImpacts, hasLength(1));
        expect(result.goalImpacts.single.goalName, 'Emergency Fund');
        expect(result.goalImpacts.single.originalTargetDate, '2026-12-31');
        expect(result.goalImpacts.single.delayedTargetDate, '2027-01-20');
        expect(result.goalImpacts.single.delayDays, 20);

        final call = stack.api
            .callsTo('POST', '/forecasting/purchase-check')
            .single;
        expect(
          call.bodyAsMap,
          equals({'itemTitle': 'Mechanical Keyboard', 'amount': 4999.5}),
        );
      },
    );
  });

  group('offline and filtered transactions', () {
    late FakeEngineStack stack;
    late TransactionMutator mutator;
    late List<ProviderProbe> hubProbes;
    late ProviderProbe dashboard;
    late ProviderProbe paginated;
    late ProviderProbe transactions;
    late ProviderProbe alerts;
    late ProviderProbe accounts;
    late ProviderProbe balances;
    late ProviderProbe planning;
    late ProviderProbe budgetStatus;
    late ProviderProbe goals;
    late ProviderProbe bills;
    late ProviderProbe userProfile;
    late ProviderProbe categories;
    late ProviderProbe goalOne;
    late ProviderProbe goalTwo;

    setUp(() async {
      stack = await FakeEngineStack.create();
      mutator = stack.mutator;

      dashboard = stack.probe('dashboard', dashboardProvider);
      paginated = stack.probe(
        'paginatedTransactions',
        paginatedTransactionsProvider,
      );
      transactions = stack.probe('transactions', transactionsProvider);
      alerts = stack.probe('alerts', alertsProvider);
      accounts = stack.probe('accounts', accountsProvider);
      balances = stack.probe('accountBalances', accountBalancesProvider);
      planning = stack.probe('planning', planningProvider);
      budgetStatus = stack.probe('budgetStatus', budgetStatusProvider);
      goals = stack.probe('goals', goalsProvider);
      bills = stack.probe('bills', billsProvider);
      userProfile = stack.probe('userProfile', userProfileProvider);
      categories = stack.probe('categories', categoriesProvider);
      goalOne = stack.probeAutoDispose(
        'goalDetail(g1)',
        goalDetailProvider('g1'),
      );
      goalTwo = stack.probeAutoDispose(
        'goalDetail(g2)',
        goalDetailProvider('g2'),
      );

      hubProbes = [
        accounts,
        balances,
        dashboard,
        paginated,
        transactions,
        alerts,
        planning,
        budgetStatus,
        goals,
        bills,
      ];
      await stack.warm([
        ...hubProbes,
        userProfile,
        categories,
        goalOne,
        goalTwo,
      ]);
    });

    tearDown(() async {
      await stack.dispose();
    });

    test(
      'a connection failure queues addExpense and still invalidates the hub',
      () async {
        final emissionsBefore = stack.emissionsSnapshot([
          ...hubProbes,
          userProfile,
          categories,
          goalOne,
          goalTwo,
        ]);
        final endpointsBefore = stack.api.snapshot();

        stack.api.on('POST', '/expenses', (call) {
          throw DioException.connectionError(
            requestOptions: call.requestOptions,
            reason: 'qa offline',
          );
        });

        final status = await mutator.addExpense(
          accountId: 'acct-1',
          categoryId: _categoryId,
          amount: 99.25,
          description: 'Offline coffee',
          spentAt: _postedDate,
        );

        expect(status, TransactionSaveStatus.queued);
        expect(stack.api.count('POST', '/expenses'), 1);
        expect(stack.cache.entries, hasLength(1));

        final queued = stack.cache.entries.single;
        expect(queued.type, 'expense');
        expect(queued.userId, _userId);
        final queuedBody = jsonDecode(queued.json) as Map<String, dynamic>;
        expect(queuedBody['accountId'], 'acct-1');
        expect(queuedBody['categoryId'], _categoryId);
        expect(queuedBody['amount'], '99.25');
        expect(queuedBody['description'], 'Offline coffee');
        expect(queuedBody['status'], 'posted');

        await stack.warm([
          ...hubProbes,
          userProfile,
          categories,
          goalOne,
          goalTwo,
        ]);
        final endpointsAfter = stack.api.snapshot();

        _expectRefreshed(hubProbes, emissionsBefore);
        _expectUntouched([
          userProfile,
          categories,
          goalOne,
          goalTwo,
        ], emissionsBefore);
        _expectEndpoints(endpointsBefore, endpointsAfter, _fullHubEndpoints);
      },
    );

    test(
      'transactionFilterProvider forwards from/to and merges only in-range pending entries',
      () async {
        await stack.cache.seedTransaction(
          id: 'offline-in-range',
          type: 'expense',
          userId: _userId,
          data: {
            'amount': '100.00',
            'description': 'In Range',
            'categoryName': 'Food',
            'spentAt': '2026-05-15',
          },
          createdAt: DateTime(2026, 5, 15),
        );
        await stack.cache.seedTransaction(
          id: 'offline-out-of-range',
          type: 'expense',
          userId: _userId,
          data: {
            'amount': '200.00',
            'description': 'Out of Range',
            'categoryName': 'Food',
            'spentAt': '2026-07-15',
          },
          createdAt: DateTime(2026, 7, 15),
        );

        stack.container
            .read(transactionFilterProvider.notifier)
            .state = TransactionQueryFilter(
          page: 1,
          limit: 50,
          fromDate: DateTime(2026, 5, 1),
          toDate: DateTime(2026, 5, 31),
        );

        final page = await stack.container.read(
          paginatedTransactionsProvider.future,
        );

        expect(page.items, hasLength(1));
        expect(page.items.single.id, 'offline-in-range');
        expect(page.items.single.title, 'In Range');
        // Filtered-out pending entries must not inflate the pagination count.
        expect(page.totalCount, 1);

        final call = stack.api.callsTo('GET', '/transactions').last;
        expect(call.queryParameters['from'], '2026-05-01');
        expect(call.queryParameters['to'], '2026-05-31');
        expect(call.queryParameters['page'], 1);
        expect(call.queryParameters['limit'], 50);
      },
    );
  });
}

Future<void> _expectHubRefresh(
  FakeEngineStack stack,
  TransactionMutator mutator,
  List<ProviderProbe> allProbes,
  _MutationRunner mutation,
  List<ProviderProbe> refreshed,
  List<ProviderProbe> untouched, {
  Map<String, int> endpoints = _fullHubEndpoints,
}) async {
  final emissionsBefore = stack.emissionsSnapshot(allProbes);
  final endpointsBefore = stack.api.snapshot();

  await mutation(mutator);

  await stack.warm(allProbes);
  final endpointsAfter = stack.api.snapshot();

  _expectRefreshed(refreshed, emissionsBefore);
  _expectUntouched(untouched, emissionsBefore);
  _expectEndpoints(endpointsBefore, endpointsAfter, endpoints);
}

Future<void> _expectAccountRefresh(
  FakeEngineStack stack,
  List<ProviderProbe> allProbes,
  _MutationRunner mutation,
  List<ProviderProbe> refreshed,
  List<ProviderProbe> untouched,
) async {
  final emissionsBefore = stack.emissionsSnapshot(allProbes);
  final endpointsBefore = stack.api.snapshot();

  await mutation(stack.mutator);

  await stack.warm(allProbes);
  final endpointsAfter = stack.api.snapshot();

  _expectRefreshed(refreshed, emissionsBefore);
  _expectUntouched(untouched, emissionsBefore);
  _expectEndpoints(endpointsBefore, endpointsAfter, const {
    'GET /accounts': 1,
    'GET /accounts/acct-1/balance': 1,
    'GET /dashboard': 1,
    'GET /planning/overview': 1,
    'GET /alerts': 1,
    'GET /transactions': 0,
    'GET /bills': 0,
    'GET /budgets/status': 0,
    'GET /goals': 0,
    'GET /auth/me': 0,
    'GET /expense-categories': 0,
    'GET /goals/g1': 0,
    'GET /goals/g2': 0,
  });
}

void _expectRefreshed(
  List<ProviderProbe> expected,
  Map<ProviderProbe, int> before,
) {
  for (final probe in expected) {
    expect(
      probe.emissions,
      greaterThan(before[probe] ?? 0),
      reason: '${probe.name} should have refetched',
    );
  }
}

void _expectUntouched(
  List<ProviderProbe> untouched,
  Map<ProviderProbe, int> before,
) {
  for (final probe in untouched) {
    expect(
      probe.emissions,
      before[probe] ?? 0,
      reason: '${probe.name} should not have refetched',
    );
  }
}

void _expectEndpoints(
  EndpointCounts before,
  EndpointCounts after,
  Map<String, int> expected,
) {
  for (final entry in expected.entries) {
    expect(
      after.delta(before, entry.key),
      entry.value,
      reason: 'unexpected call count for ${entry.key}',
    );
  }
}
