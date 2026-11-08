// Session-scoped cache invalidation regression coverage.
//
// `sessionDataResetProvider` listens to the authenticated user id and, when it
// changes, invalidates every long-lived finance provider and resets the
// transaction pager.
//
// The logout test drives the real AuthNotifier. The identity-swap test uses a
// test-only AuthNotifier subclass because the real `login()` emits an interim
// `isLoading` state that independently rebuilds auth-watching providers before
// the user id changes; a single state assignment lets us assert the listener's
// exact-once contract without counting that pre-existing loading refetch.
//
// Every provider invalidated by `invalidateFinanceData` is warmed before the
// auth change. This matters in debug mode: Riverpod's `invalidate` debug
// assertion initializes unknown providers, which would otherwise add unrelated
// requests to the call counts.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/api/api_client.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/database/cache_service.dart';
import 'package:kasyaba/core/database/database.dart';
import 'package:kasyaba/core/database/database_provider.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/providers/session_refresh_provider.dart';
import 'package:kasyaba/core/storage/secure_storage_service.dart';

import '../support/fake_engine_stack.dart';

/// A single (synchronous) auth identity swap, bypassing AuthNotifier's
/// intermediate `isLoading` state.
class _MutableAuthNotifier extends AuthNotifier {
  _MutableAuthNotifier(Dio dio, SecureStorageService storage)
      : super(dio, storage, const Stream<void>.empty());

  void setUserIdForTest(String userId) {
    state = AuthState(
      isAuthenticated: true,
      userId: userId,
      email: '$userId@example.test',
      displayName: 'QA $userId',
    );
  }
}

class _TestProbe {
  _TestProbe(this.name, FutureProvider<dynamic> provider, ProviderContainer container) {
    container.listen<AsyncValue<dynamic>>(provider, (previous, next) {
      if (next is AsyncData<dynamic>) _emissions++;
    });
    _container = container;
    _provider = provider;
  }

  final String name;
  late final ProviderContainer _container;
  late final FutureProvider<dynamic> _provider;
  int _emissions = 0;

  int get emissions => _emissions;

  Future<void> read() async {
    await _container.read(_provider.future);
  }
}

Future<ProviderContainer> _createMutableStack(
  Dio dio,
  FakeSecureStorage storage,
  AppDatabase database,
  FakeCacheService cache,
  _MutableAuthNotifier Function() notifierFactory,
) async {
  final container = ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
      secureStorageProvider.overrideWithValue(storage),
      authProvider.overrideWith((ref) => notifierFactory()),
      databaseProvider.overrideWithValue(database),
      cacheServiceProvider.overrideWithValue(cache),
    ],
  );

  for (var attempt = 0; attempt < 400; attempt++) {
    final auth = container.read(authProvider);
    if (!auth.isInitializing && auth.isAuthenticated) return container;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Mutable auth stack did not restore the QA user.');
}

void main() {
  group('session data reset', () {
    late FakeEngineStack stack;
    late ProviderProbe bills;
    late ProviderProbe dashboard;
    late ProviderProbe alerts;
    late ProviderProbe paginated;
    late ProviderProbe transactions;
    late ProviderProbe planning;
    late ProviderProbe balances;
    late ProviderProbe accounts;
    late ProviderProbe budgetStatus;
    late ProviderProbe goals;
    late ProviderProbe userProfile;
    late ProviderProbe goalOne;
    late List<ProviderProbe> allProbes;

    setUp(() async {
      stack = await FakeEngineStack.create();

      // Activate the listener only after the container has restored the
      // initial session; the restore must not be treated as an identity swap.
      stack.container.read(sessionDataResetProvider);

      bills = stack.probe('bills', billsProvider);
      dashboard = stack.probe('dashboard', dashboardProvider);
      alerts = stack.probe('alerts', alertsProvider);
      paginated = stack.probe(
        'paginatedTransactions',
        paginatedTransactionsProvider,
      );
      transactions = stack.probe('transactions', transactionsProvider);
      planning = stack.probe('planning', planningProvider);
      balances = stack.probe('accountBalances', accountBalancesProvider);
      accounts = stack.probe('accounts', accountsProvider);
      budgetStatus = stack.probe('budgetStatus', budgetStatusProvider);
      goals = stack.probe('goals', goalsProvider);
      userProfile = stack.probe('userProfile', userProfileProvider);
      goalOne = stack.probeAutoDispose(
        'goalDetail(g1)',
        goalDetailProvider('g1'),
      );

      allProbes = [
        bills,
        dashboard,
        alerts,
        paginated,
        transactions,
        planning,
        balances,
        accounts,
        budgetStatus,
        goals,
        userProfile,
        goalOne,
      ];

      // A non-default pager is the observable proof that the reset actually
      // rewrote the filter state rather than just refetching page 1.
      stack.container.read(transactionFilterProvider.notifier).state =
          TransactionQueryFilter(
            page: 3,
            limit: 25,
            fromDate: DateTime(2026, 10, 1),
            toDate: DateTime(2026, 10, 31),
          );

      await stack.warm(allProbes);
    });

    tearDown(() async {
      await stack.dispose();
    });

    test(
      'logging out resets the filter and refetches every signed-out-safe '
      'provider exactly once',
      () async {
        // Keep the logout request deterministic instead of relying on the
        // adapter's generic 404 path.
        stack.api.json('POST', '/auth/logout', <String, dynamic>{
          'data': <String, dynamic>{},
        });

        final emissionsBefore = stack.emissionsSnapshot(allProbes);
        final callsBefore = stack.api.snapshot();

        await stack.container.read(authProvider.notifier).logout();

        expect(stack.container.read(authProvider).isAuthenticated, isFalse);
        expect(stack.container.read(authProvider).userId, isNull);
        expect(stack.storage.values.containsKey('access_token'), isFalse);

        // Dashboard data is user-scoped and cannot be fetched while signed
        // out, so it is excluded from the warm and must enter an error state.
        await stack.warm(
          allProbes.where((probe) => probe != dashboard),
        );
        final callsAfter = stack.api.snapshot();

        for (final probe in allProbes.where((probe) => probe != dashboard)) {
          expect(
            probe.emissions,
            greaterThan(emissionsBefore[probe] ?? 0),
            reason: '${probe.name} must refetch after logout',
          );
        }

        final dashboardState = stack.container.read(dashboardProvider);
        expect(
          dashboardState,
          isA<AsyncError<DashboardData>>(),
          reason: 'dashboard must not keep serving the previous user snapshot',
        );
        expect(
          (dashboardState as AsyncError<DashboardData>).error,
          isA<StateError>(),
        );

        const expectedRefetches = <String, int>{
          'GET /dashboard': 0,
          'GET /transactions': 1,
          'GET /alerts': 1,
          'GET /bills': 1,
          'GET /planning/overview': 1,
          'GET /accounts': 1,
          'GET /accounts/acct-1/balance': 1,
          'GET /budgets/status': 1,
          'GET /goals': 1,
          'GET /auth/me': 1,
          'GET /goals/g1': 1,
        };
        for (final entry in expectedRefetches.entries) {
          expect(
            callsAfter.delta(callsBefore, entry.key),
            entry.value,
            reason: 'unexpected refetch count for ${entry.key} after logout',
          );
        }

        final filter = stack.container.read(transactionFilterProvider);
        expect(filter.page, 1);
        expect(filter.limit, 50);
        expect(filter.fromDate, isNull);
        expect(filter.toDate, isNull);

        final lastTransactionsCall =
            stack.api.callsTo('GET', '/transactions').last;
        expect(lastTransactionsCall.queryParameters['page'], 1);
        expect(lastTransactionsCall.queryParameters['limit'], 50);
        expect(lastTransactionsCall.queryParameters.containsKey('from'), isFalse);
        expect(lastTransactionsCall.queryParameters.containsKey('to'), isFalse);
      },
    );

    test(
      'a single auth identity swap resets the filter and refetches every '
      'cached finance provider exactly once',
      () async {
        // Reuse the stack's Dio/storage/cache/database; only the auth notifier
        // and the provider graph are rebuilt so a single identity swap can be
        // driven synchronously.
        final api = stack.api;
        final storage = stack.storage;
        final dio = stack.dio;
        late _MutableAuthNotifier authNotifier;
        final container = await _createMutableStack(
          dio,
          storage,
          stack.database,
          stack.cache,
          () => authNotifier = _MutableAuthNotifier(dio, storage),
        );
        addTearDown(container.dispose);

        container.read(sessionDataResetProvider);

        final probes = [
          _TestProbe('bills', billsProvider, container),
          _TestProbe('dashboard', dashboardProvider, container),
          _TestProbe('alerts', alertsProvider, container),
          _TestProbe('paginated', paginatedTransactionsProvider, container),
          _TestProbe('transactions', transactionsProvider, container),
          _TestProbe('planning', planningProvider, container),
          _TestProbe('balances', accountBalancesProvider, container),
          _TestProbe('accounts', accountsProvider, container),
          _TestProbe('budgetStatus', budgetStatusProvider, container),
          _TestProbe('goals', goalsProvider, container),
          _TestProbe('userProfile', userProfileProvider, container),
        ];

        container.read(transactionFilterProvider.notifier).state =
            TransactionQueryFilter(
              page: 3,
              limit: 25,
              fromDate: DateTime(2026, 10, 1),
              toDate: DateTime(2026, 10, 31),
            );

        await Future.wait(probes.map((probe) => probe.read()));

        final emissionsBefore = <_TestProbe, int>{
          for (final probe in probes) probe: probe.emissions,
        };
        final callsBefore = api.snapshot();

        authNotifier.setUserIdForTest('qa-user-2');

        await Future.wait(probes.map((probe) => probe.read()));
        final callsAfter = api.snapshot();

        for (final probe in probes) {
          expect(
            probe.emissions,
            greaterThan(emissionsBefore[probe] ?? 0),
            reason: '${probe.name} must refetch after the user id changes',
          );
        }

        const expectedRefetches = <String, int>{
          'GET /dashboard': 1,
          'GET /transactions': 1,
          'GET /alerts': 1,
          'GET /bills': 1,
          'GET /planning/overview': 1,
          'GET /accounts': 1,
          'GET /accounts/acct-1/balance': 1,
          'GET /budgets/status': 1,
          'GET /goals': 1,
          'GET /auth/me': 1,
        };
        for (final entry in expectedRefetches.entries) {
          expect(
            callsAfter.delta(callsBefore, entry.key),
            entry.value,
            reason:
                'unexpected refetch count for ${entry.key} after identity swap',
          );
        }

        final filter = container.read(transactionFilterProvider);
        expect(filter.page, 1);
        expect(filter.limit, 50);
        expect(filter.fromDate, isNull);
        expect(filter.toDate, isNull);

        final lastTransactionsCall = api.callsTo('GET', '/transactions').last;
        expect(lastTransactionsCall.queryParameters['page'], 1);
        expect(lastTransactionsCall.queryParameters['limit'], 50);
        expect(lastTransactionsCall.queryParameters.containsKey('from'), isFalse);
        expect(lastTransactionsCall.queryParameters.containsKey('to'), isFalse);
      },
    );

    test('an unchanged session does not reset the filter or refetch', () async {
      final emissionsBefore = stack.emissionsSnapshot(allProbes);
      final callsBefore = stack.api.snapshot();

      // Same auth identity, no login/logout: nothing may be invalidated.
      await stack.warm(allProbes);

      final callsAfter = stack.api.snapshot();
      for (final probe in allProbes) {
        expect(
          probe.emissions,
          emissionsBefore[probe],
          reason: '${probe.name} refetched without an auth identity change',
        );
      }
      for (final endpoint in <String>[
        'GET /dashboard',
        'GET /transactions',
        'GET /alerts',
        'GET /bills',
        'GET /planning/overview',
        'GET /accounts',
        'GET /accounts/acct-1/balance',
        'GET /budgets/status',
        'GET /goals',
        'GET /auth/me',
        'GET /goals/g1',
      ]) {
        expect(
          callsAfter.delta(callsBefore, endpoint),
          0,
          reason: '$endpoint refetched without an auth identity change',
        );
      }

      final filter = stack.container.read(transactionFilterProvider);
      expect(filter.page, 3);
      expect(filter.limit, 25);
      expect(filter.fromDate, DateTime(2026, 10, 1));
      expect(filter.toDate, DateTime(2026, 10, 31));
    });
  });
}
