import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasyaba/core/api/api_client.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/database/cache_service.dart';
import 'package:kasyaba/core/database/database.dart';
import 'package:kasyaba/core/database/database_provider.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/storage/secure_storage_service.dart';

/// A single HTTP request captured by [FakeApiAdapter].
class FakeApiCall {
  FakeApiCall({
    required this.method,
    required this.path,
    required this.queryParameters,
    required this.body,
    required this.requestOptions,
  });

  final String method;
  final String path;
  final Map<String, dynamic> queryParameters;
  final Object? body;
  final RequestOptions requestOptions;

  String get endpoint => '$method $path';

  Map<String, dynamic> get bodyAsMap {
    final value = body;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw StateError('Request body for $endpoint is not a JSON object: $value');
  }
}

/// A canned response returned by [FakeApiAdapter].
class FakeApiResponse {
  const FakeApiResponse(this.body, {this.statusCode = 200});

  final Object? body;
  final int statusCode;
}

typedef FakeApiHandler = FutureOr<FakeApiResponse> Function(FakeApiCall call);

class _FakeRoute {
  _FakeRoute({required this.method, required this.path, required this.handler});

  final String method;
  final Pattern path;
  final FakeApiHandler handler;

  bool matches(String actualPath) {
    final pattern = path;
    if (pattern is RegExp) return pattern.hasMatch(actualPath);
    return pattern == actualPath;
  }
}

/// Counts captured requests by their `METHOD /path` endpoint key.
class EndpointCounts {
  const EndpointCounts(this._counts);

  final Map<String, int> _counts;

  int operator [](String endpoint) => _counts[endpoint] ?? 0;

  int delta(EndpointCounts before, String endpoint) =>
      this[endpoint] - before[endpoint];

  Map<String, int> get raw => Map.unmodifiable(_counts);
}

/// In-memory Dio adapter with a mutable first-match-wins route table.
///
/// Routes registered later take precedence, which lets a test override a
/// default canned response without rebuilding the stack.
class FakeApiAdapter implements HttpClientAdapter {
  FakeApiAdapter({bool withDefaults = true}) {
    if (withDefaults) _installDefaultRoutes();
  }

  final List<FakeApiCall> calls = <FakeApiCall>[];
  final List<_FakeRoute> _routes = <_FakeRoute>[];

  void on(String method, Pattern path, FakeApiHandler handler) {
    _routes.insert(
      0,
      _FakeRoute(method: method.toUpperCase(), path: path, handler: handler),
    );
  }

  void json(String method, Pattern path, Object? body, {int statusCode = 200}) {
    on(method, path, (_) => FakeApiResponse(body, statusCode: statusCode));
  }

  List<FakeApiCall> callsTo(String method, [Pattern? path]) {
    final normalizedMethod = method.toUpperCase();
    return calls.where((call) {
      if (call.method != normalizedMethod) return false;
      if (path == null) return true;
      if (path is RegExp) return path.hasMatch(call.path);
      return call.path == path;
    }).toList();
  }

  int count(String method, Pattern path) => callsTo(method, path).length;

  EndpointCounts snapshot() {
    final counts = <String, int>{};
    for (final call in calls) {
      counts.update(call.endpoint, (value) => value + 1, ifAbsent: () => 1);
    }
    return EndpointCounts(counts);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = await _decodeBody(options, requestStream);
    final call = FakeApiCall(
      method: options.method.toUpperCase(),
      path: options.path,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      body: body,
      requestOptions: options,
    );
    calls.add(call);

    for (final route in _routes) {
      if (route.method != call.method || !route.matches(call.path)) continue;
      final response = await route.handler(call);
      return _jsonResponse(response.statusCode, response.body);
    }

    return _jsonResponse(404, {
      'error': {'message': 'not found'},
    });
  }

  @override
  void close({bool force = false}) {}

  Future<Object?> _decodeBody(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  ) async {
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      if (bytes.isNotEmpty) {
        final text = utf8.decode(bytes);
        try {
          return jsonDecode(text);
        } on FormatException {
          return text;
        }
      }
    }

    final data = options.data;
    if (data is String) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return data;
      }
    }
    return data;
  }

  ResponseBody _jsonResponse(int statusCode, Object? body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  void _installDefaultRoutes() {
    json('GET', '/auth/me', {
      'data': {
        'id': 'qa-user',
        'email': 'qa@example.test',
        'displayName': 'QA User',
        'hasPassword': true,
      },
    });
    json('GET', '/dashboard', {
      'data': {
        'balance': '1000.00',
        'income': '500.00',
        'expenses': '250.00',
        'savings': '100.00',
        'healthGrade': 'Good',
        'predictedMonthEndBalance': '900.00',
        'budgetUsedPercent': 10,
        'charts': {
          'expensesByCategory': <dynamic>[],
          'dailyBalance': <dynamic>[],
        },
      },
    });
    json('GET', '/transactions', {
      'data': <dynamic>[],
      'meta': {'total': 0},
    });
    json('GET', '/alerts', {'data': <dynamic>[]});
    json('GET', '/accounts', {
      'data': [
        {'id': 'acct-1', 'name': 'Cash Wallet', 'type': 'cash'},
      ],
    });
    on(
      'GET',
      RegExp(r'^/accounts/[^/]+/balance$'),
      (_) => const FakeApiResponse({
        'data': {'balance': '1000.00'},
      }),
    );
    json('GET', '/planning/overview', {
      'data': {
        'from': '2026-11-01',
        'to': '2026-11-30',
        'currentBalance': '1000.00',
        'minimumBalanceThreshold': '0.00',
        'totalPlannedIncome': '0.00',
        'totalPlannedExpenses': '0.00',
        'totalUpcomingBills': '0.00',
        'projectedClosingBalance': '1000.00',
        'availableBuffer': '1000.00',
        'safeToSpendPerDay': '33.33',
        'daysInWindow': 30,
        'status': 'clear',
        'calculationNote': 'qa',
        'days': <dynamic>[],
      },
    });
    json('GET', '/budgets/status', {
      'data': {
        'month': '2026-11',
        'totalBudget': '0.00',
        'totalSpent': '0.00',
        'overallPercent': 0,
        'budgetCount': 0,
        'budgets': <dynamic>[],
      },
    });
    json('GET', '/goals', {'data': <dynamic>[]});
    on('GET', RegExp(r'^/goals/[^/]+$'), (call) {
      final id = call.path.split('/').last;
      return FakeApiResponse({
        'data': {
          'id': id,
          'name': 'Goal $id',
          'targetAmount': '1000.00',
          'currentAmount': '0.00',
        },
      });
    });
    json('GET', '/bills', {'data': <dynamic>[]});
    json('GET', '/expense-categories', {'data': <dynamic>[]});

    json('POST', '/expenses', {
      'data': {'id': 'created-expense'},
    });
    json('POST', '/income', {
      'data': {'id': 'created-income'},
    });
    json('POST', '/transfers', {
      'data': {'id': 'created-transfer'},
    });
    on(
      'PATCH',
      RegExp(r'^/expenses/[^/]+$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );
    on(
      'PATCH',
      RegExp(r'^/income/[^/]+$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );
    on(
      'DELETE',
      RegExp(r'^/expenses/[^/]+$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );
    on(
      'DELETE',
      RegExp(r'^/income/[^/]+$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );
    on(
      'DELETE',
      RegExp(r'^/transfers/[^/]+$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );

    json('POST', '/accounts', {
      'data': {'id': 'acct-new'},
    });
    on(
      'POST',
      RegExp(r'^/accounts/[^/]+/archive$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );
    json('POST', '/expense-categories', {
      'data': {
        'id': '22222222-2222-4222-8222-222222222222',
        'name': 'Created Category',
        'iconKey': 'receipt',
      },
    });

    json('POST', '/budgets', {
      'data': {'id': 'budget-new'},
    });
    on(
      'DELETE',
      RegExp(r'^/budgets/[^/]+$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );

    json('POST', '/goals', {
      'data': {
        'id': 'goal-new',
        'name': 'New Goal',
        'targetAmount': '0.00',
        'currentAmount': '0.00',
      },
    });
    on(
      'PATCH',
      RegExp(r'^/goals/[^/]+$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );
    on(
      'DELETE',
      RegExp(r'^/goals/[^/]+$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );
    on(
      'POST',
      RegExp(r'^/goals/[^/]+/contributions$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );

    json('POST', '/bill-templates', {
      'data': {'id': 'bill-template-new'},
    });
    on(
      'POST',
      RegExp(r'^/bills/[^/]+/mark-paid$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );
    on(
      'POST',
      RegExp(r'^/bills/[^/]+/mark-unpaid$'),
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );

    on(
      'PATCH',
      '/auth/me',
      (_) => const FakeApiResponse({'data': <String, dynamic>{}}),
    );

    json('POST', '/forecasting/purchase-check', {
      'data': {'itemTitle': 'Default'},
    });
  }
}

/// In-memory secure storage; every auth method consumed by [AuthNotifier]
/// reads and writes the same plain-string map the real service uses.
class FakeSecureStorage extends SecureStorageService {
  FakeSecureStorage({Map<String, String>? initial})
    : _values = <String, String>{...?initial};

  FakeSecureStorage.authenticated({
    String userId = 'qa-user',
    String accessToken = 'qa-access-token',
  }) : _values = <String, String>{
         'access_token': accessToken,
         'refresh_token': 'qa-refresh-token',
         'auth_user_id': userId,
         'auth_user_email': 'qa@example.test',
         'auth_user_display_name': 'QA User',
       };

  static const _authKeys = <String>{
    'access_token',
    'refresh_token',
    'auth_user_id',
    'auth_user_email',
    'auth_user_display_name',
  };

  final Map<String, String> _values;

  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  Future<String?> readRaw(String key) async => _values[key];

  @override
  Future<void> writeRaw(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<String?> getAccessToken() async => _values['access_token'];

  @override
  Future<String?> getRefreshToken() async => _values['refresh_token'];

  @override
  Future<Map<String, String>?> getCachedUser() async {
    final userId = _values['auth_user_id'];
    final email = _values['auth_user_email'];
    if (userId == null || email == null) return null;
    final displayName = _values['auth_user_display_name'];
    return {
      'id': userId,
      'email': email,
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
    };
  }

  @override
  Future<void> saveTokens(
    String accessToken,
    String refreshToken, {
    String? userId,
    String? email,
    String? displayName,
  }) async {
    _values['access_token'] = accessToken;
    _values['refresh_token'] = refreshToken;
    if (userId != null && email != null) {
      _values['auth_user_id'] = userId;
      _values['auth_user_email'] = email;
      _values['auth_user_display_name'] = displayName ?? '';
    } else {
      _values.remove('auth_user_id');
      _values.remove('auth_user_email');
      _values.remove('auth_user_display_name');
    }
  }

  @override
  Future<void> saveUser({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    _values['auth_user_id'] = userId;
    _values['auth_user_email'] = email;
    _values['auth_user_display_name'] = displayName ?? '';
  }

  @override
  Future<void> clearTokens() async {
    for (final key in _authKeys) {
      _values.remove(key);
    }
  }
}

/// A permissive drift executor that is intentionally never used.
///
/// [FakeCacheService] overrides every public [CacheService] method, so the
/// underlying database is only needed to satisfy the constructor.
class NoopQueryExecutor extends QueryExecutor {
  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async => const <Map<String, Object?>>[];

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  @override
  TransactionExecutor beginTransaction() => _NoopTransactionExecutor();

  @override
  QueryExecutor beginExclusive() => _NoopTransactionExecutor();

  @override
  Future<void> close() async {}
}

class _NoopTransactionExecutor extends NoopQueryExecutor
    implements TransactionExecutor {
  @override
  bool get supportsNestedTransactions => false;

  @override
  Future<void> send() async {}

  @override
  Future<void> rollback() async {}
}

/// In-memory replacement for the offline queue.
class FakeCacheService extends CacheService {
  FakeCacheService([AppDatabase? database])
    : super(database ?? AppDatabase(NoopQueryExecutor()));

  final List<OfflineTransaction> entries = <OfflineTransaction>[];
  final Map<String, StreamController<List<OfflineTransaction>>> _watchers =
      <String, StreamController<List<OfflineTransaction>>>{};

  DashboardData? _cachedDashboard;
  int _nextId = 0;

  @override
  Future<void> cacheDashboard(DashboardData data, String userId) async {
    _cachedDashboard = data;
  }

  @override
  Future<DashboardData?> getCachedDashboard(String userId) async =>
      _cachedDashboard;

  @override
  Future<String> queueTransaction({
    required String type,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final id = 'queued-${++_nextId}';
    entries.add(
      OfflineTransaction(
        id: id,
        userId: userId,
        type: type,
        json: jsonEncode(data),
        createdAt: DateTime.now(),
        retryCount: 0,
      ),
    );
    _emit(userId);
    return id;
  }

  /// Test helper: seeds a queued transaction without advancing mock time.
  void seedTransaction({
    required String id,
    required String type,
    required String userId,
    required Map<String, dynamic> data,
    DateTime? createdAt,
  }) {
    entries.add(
      OfflineTransaction(
        id: id,
        userId: userId,
        type: type,
        json: jsonEncode(data),
        createdAt: createdAt ?? DateTime.now(),
        retryCount: 0,
      ),
    );
    _emit(userId);
  }

  @override
  Future<List<OfflineTransaction>> getPendingSyncTransactions(
    String userId,
  ) async => _pending(userId);

  @override
  Future<List<OfflineTransaction>> getAllOfflineTransactions(
    String userId,
  ) async => entries
      .where((entry) => entry.userId == userId && entry.syncedAt == null)
      .toList();

  @override
  Stream<List<OfflineTransaction>> watchPendingSyncTransactions(String userId) {
    final controller = _watchers.putIfAbsent(userId, () {
      late final StreamController<List<OfflineTransaction>> controller;
      controller = StreamController<List<OfflineTransaction>>.broadcast(
        onListen: () => controller.add(_pending(userId)),
      );
      return controller;
    });
    return controller.stream;
  }

  @override
  Future<int> syncPendingTransactions(Dio dio, String userId) async => 0;

  @override
  Future<void> markSynced(String id) async {}

  @override
  Future<void> recordRetry(
    OfflineTransaction transaction,
    String message,
  ) async {}

  @override
  Future<void> markFailed(String id, String message) async {}

  @override
  Future<void> retryFailedTransaction(String id) async {}

  @override
  Future<void> deleteOfflineTransaction(String id) async {
    entries.removeWhere((entry) => entry.id == id);
  }

  List<OfflineTransaction> _pending(String userId) => entries
      .where(
        (entry) =>
            entry.userId == userId &&
            entry.syncedAt == null &&
            entry.failedAt == null,
      )
      .toList();

  void _emit(String userId) {
    final controller = _watchers[userId];
    if (controller != null && !controller.isClosed && controller.hasListener) {
      controller.add(_pending(userId));
    }
  }

  Future<void> dispose() async {
    for (final controller in _watchers.values) {
      await controller.close();
    }
    _watchers.clear();
  }
}

/// Counts completed provider rebuilds for a single provider.
class ProviderProbe {
  ProviderProbe._({
    required this.name,
    required this._emissions,
    required this._read,
  });

  final String name;
  final int Function() _emissions;
  final Future<void> Function() _read;

  int get emissions => _emissions();

  Future<void> read() => _read();
}

/// Wires a fake Dio, fake secure storage, fake offline cache, and an
/// authenticated [AuthNotifier] into a [ProviderContainer].
class FakeEngineStack {
  FakeEngineStack._({
    required this.api,
    required this.storage,
    required this.cache,
    required this.database,
    required this.dio,
    required this.container,
  });

  final FakeApiAdapter api;
  final FakeSecureStorage storage;
  final FakeCacheService cache;
  final AppDatabase database;
  final Dio dio;
  final ProviderContainer container;

  final List<ProviderSubscription<dynamic>> _subscriptions =
      <ProviderSubscription<dynamic>>[];

  TransactionMutator get mutator => container.read(transactionMutatorProvider);

  static Future<FakeEngineStack> create() async {
    final api = FakeApiAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = api;
    final storage = FakeSecureStorage.authenticated();
    final database = AppDatabase(NoopQueryExecutor());
    final cache = FakeCacheService(database);
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        secureStorageProvider.overrideWithValue(storage),
        authProvider.overrideWith(
          (ref) => AuthNotifier(dio, storage, const Stream<void>.empty()),
        ),
        databaseProvider.overrideWithValue(database),
        cacheServiceProvider.overrideWithValue(cache),
      ],
    );

    final stack = FakeEngineStack._(
      api: api,
      storage: storage,
      cache: cache,
      database: database,
      dio: dio,
      container: container,
    );
    await stack.waitForAuthenticatedUser();
    return stack;
  }

  /// Polls until [AuthNotifier.checkAuth] has restored the QA user.
  Future<void> waitForAuthenticatedUser({String userId = 'qa-user'}) async {
    for (var attempt = 0; attempt < 400; attempt++) {
      final auth = container.read(authProvider);
      if (!auth.isInitializing &&
          auth.isAuthenticated &&
          auth.userId == userId) {
        return;
      }
      await Future<void>.value();
      if (attempt % 25 == 24) {
        // Let any event-loop continuations queued by Dio run as well.
        await Future<void>.delayed(Duration.zero);
      }
    }
    final auth = container.read(authProvider);
    throw StateError(
      'Auth did not authenticate $userId: authenticated=${auth.isAuthenticated} '
      'userId=${auth.userId} initializing=${auth.isInitializing} '
      'error=${auth.error}',
    );
  }

  ProviderProbe probe<T>(String name, FutureProvider<T> provider) {
    return _probe(name, provider, provider.future);
  }

  ProviderProbe probeAutoDispose<T>(
    String name,
    AutoDisposeFutureProvider<T> provider,
  ) {
    return _probe(name, provider, provider.future);
  }

  ProviderProbe _probe<T>(
    String name,
    ProviderListenable<AsyncValue<T>> listenable,
    Refreshable<Future<T>> future,
  ) {
    var emissions = 0;
    final subscription = container.listen<AsyncValue<T>>(listenable, (
      previous,
      next,
    ) {
      if (next is AsyncData<T>) emissions++;
    });
    _subscriptions.add(subscription);
    return ProviderProbe._(
      name: name,
      emissions: () => emissions,
      read: () async {
        await container.read(future);
      },
    );
  }

  Map<ProviderProbe, int> emissionsSnapshot(Iterable<ProviderProbe> probes) {
    return {for (final probe in probes) probe: probe.emissions};
  }

  Future<void> warm(Iterable<ProviderProbe> probes) async {
    for (final probe in probes) {
      await probe.read();
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    _subscriptions.clear();
    container.dispose();
    await cache.dispose();
    await database.close();
    dio.close(force: true);
  }
}
