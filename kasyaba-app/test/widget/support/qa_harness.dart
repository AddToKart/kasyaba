// QA harness shared by the `qa_*` widget tests only.
//
// This file deliberately avoids every platform channel:
//  * `QaFakeHttpClientAdapter` replaces the real network adapter.
//  * `QaFakeSecureStorage` replaces flutter_secure_storage.
//  * `pendingSyncTransactionsProvider` is overridden so Drift/path_provider is
//    never opened.
//
// Do not import this file from production code.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/app/theme/app_theme.dart';
import 'package:kasyaba/app/theme/kasyaba_tokens.dart';
import 'package:kasyaba/core/api/api_client.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/database/database.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/storage/secure_storage_service.dart';
import 'package:kasyaba/shared/widgets/app_sheet.dart';

const String qaTestUserId = '11111111-1111-4111-8111-111111111111';
const String qaTestEmail = 'qa@kasyaba.test';
const String qaAccountId = '22222222-2222-4222-8222-222222222222';
const String qaSecondAccountId = '33333333-3333-4333-8333-333333333333';

/// A request captured by [QaFakeHttpClientAdapter].
class QaRecordedRequest {
  QaRecordedRequest({
    required this.method,
    required this.path,
    required this.queryParameters,
    required this.data,
    required this.headers,
  });

  final String method;
  final String path;
  final Map<String, dynamic> queryParameters;
  final Object? data;
  final Map<String, dynamic> headers;

  bool get isPatch => method.toUpperCase() == 'PATCH';
  bool get isPost => method.toUpperCase() == 'POST';
  bool get isGet => method.toUpperCase() == 'GET';

  /// The request payload as a JSON map, regardless of how Dio presented it.
  Map<String, dynamic>? get jsonBody {
    final raw = data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() => '$method $path';
}

/// Convenience type for canned handlers.
typedef QaHttpResponder =
    QaHttpResponse Function(QaRecordedRequest request);

class QaHttpResponse {
  const QaHttpResponse({required this.statusCode, required this.payload});

  final int statusCode;
  final Object? payload;

  factory QaHttpResponse.ok(Object? payload) =>
      QaHttpResponse(statusCode: 200, payload: payload);
}

/// Tiny in-memory [HttpClientAdapter]. Every request is recorded and answered
/// deterministically; no sockets are opened.
class QaFakeHttpClientAdapter implements HttpClientAdapter {
  QaFakeHttpClientAdapter({
    Map<String, dynamic>? authProfile,
    this.responder,
  }) : authProfile = authProfile ?? Map<String, dynamic>.from(_defaultProfile);

  final Map<String, dynamic> authProfile;
  QaHttpResponder? responder;
  final List<QaRecordedRequest> requests = <QaRecordedRequest>[];

  static const Map<String, dynamic> _defaultProfile = <String, dynamic>{
    'id': qaTestUserId,
    'email': qaTestEmail,
    'displayName': 'QA User',
    'hasPassword': true,
    'salaryAmount': null,
    'paydayFrequency': 'semi-monthly',
    'paydaySchedule': '15th & 30th',
  };

  static const Map<String, dynamic> sampleBackup = <String, dynamic>{
    'exportedAt': '2026-10-17T00:00:00.000Z',
    'user': <String, dynamic>{'email': qaTestEmail},
    'accounts': <dynamic>[
      <String, dynamic>{'id': qaAccountId, 'name': 'Cash Wallet'},
    ],
    'expenses': <dynamic>[
      <String, dynamic>{'id': 'exp-1', 'amount': 100.0},
    ],
  };

  static const Map<String, dynamic> samplePurchaseCheck = <String, dynamic>{
    'itemTitle': 'QA Purchase',
    'amount': 25000.0,
    'verdict': 'AFFORDABLE',
    'statusTitle': 'Safely affordable',
    'statusMessage': 'You can cover this purchase.',
    'currentBalance': 25000.0,
    'postPurchaseBalance': 0.0,
    'projectedMonthEndBalance': 20000.0,
    'postPurchaseMonthEndBalance': -5000.0,
    'totalUpcomingBills': 0.0,
    'cashAfterBills': 0.0,
    'reasons': <dynamic>[],
  };

  List<QaRecordedRequest> calls(
    String method,
    String path, {
    bool exact = true,
  }) {
    final normalizedMethod = method.toUpperCase();
    return requests
        .where(
          (request) =>
              request.method.toUpperCase() == normalizedMethod &&
              (exact
                  ? request.path == path
                  : request.path.contains(path)),
        )
        .toList();
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final normalizedPath = _normalizePath(options);
    final recorded = QaRecordedRequest(
      method: options.method,
      path: normalizedPath,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      data: options.data,
      headers: Map<String, dynamic>.from(options.headers),
    );
    requests.add(recorded);

    final custom = responder;
    final response = custom != null
        ? custom(recorded)
        : _defaultResponse(recorded);
    return ResponseBody.fromString(
      jsonEncode(response.payload),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  String _normalizePath(RequestOptions options) {
    final path = options.path;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      var parsed = Uri.parse(path).path;
      if (parsed.startsWith('/api/v1')) {
        parsed = parsed.substring('/api/v1'.length);
      }
      return parsed;
    }
    var normalized = path;
    if (normalized.startsWith('/api/v1')) {
      normalized = normalized.substring('/api/v1'.length);
    }
    return normalized;
  }

  QaHttpResponse _defaultResponse(QaRecordedRequest request) {
    if (request.method.toUpperCase() == 'GET') {
      if (request.path == '/auth/me') {
        return QaHttpResponse.ok(<String, dynamic>{'data': authProfile});
      }
      if (request.path == '/auth/export') {
        return QaHttpResponse.ok(<String, dynamic>{'data': sampleBackup});
      }
      if (request.path == '/transactions') {
        return QaHttpResponse.ok(<String, dynamic>{
          'data': <dynamic>[],
          'meta': <String, dynamic>{'total': 0},
        });
      }
      final goalDetail = RegExp(r'^/goals/[^/]+$');
      if (goalDetail.hasMatch(request.path)) {
        return QaHttpResponse.ok(<String, dynamic>{
          'data': <String, dynamic>{'contributions': <dynamic>[]},
        });
      }
      return QaHttpResponse.ok(<String, dynamic>{'data': <String, dynamic>{}});
    }
    if (request.method.toUpperCase() == 'POST') {
      if (request.path == '/forecasting/purchase-check') {
        return QaHttpResponse.ok(<String, dynamic>{
          'data': samplePurchaseCheck,
        });
      }
      return QaHttpResponse.ok(<String, dynamic>{'data': <String, dynamic>{}});
    }
    if (request.method.toUpperCase() == 'PATCH') {
      return QaHttpResponse.ok(<String, dynamic>{'data': authProfile});
    }
    return QaHttpResponse.ok(<String, dynamic>{'data': <String, dynamic>{}});
  }

  @override
  void close({bool force = false}) {}
}

/// In-memory replacement for [SecureStorageService]; never touches a plugin.
class QaFakeSecureStorage extends SecureStorageService {
  QaFakeSecureStorage({
    bool authenticated = true,
    Map<String, String>? initialValues,
  }) : values = <String, String>{
          if (authenticated) ...<String, String>{
            'access_token': 'qa-access-token',
            'refresh_token': 'qa-refresh-token',
            'auth_user_id': qaTestUserId,
            'auth_user_email': qaTestEmail,
            'auth_user_display_name': 'QA User',
          },
          ...?initialValues,
        };

  final Map<String, String> values;

  @override
  Future<void> saveTokens(
    String accessToken,
    String refreshToken, {
    String? userId,
    String? email,
    String? displayName,
  }) async {
    values['access_token'] = accessToken;
    values['refresh_token'] = refreshToken;
    if (userId != null && email != null) {
      values['auth_user_id'] = userId;
      values['auth_user_email'] = email;
      values['auth_user_display_name'] = displayName ?? '';
    } else {
      values.remove('auth_user_id');
      values.remove('auth_user_email');
      values.remove('auth_user_display_name');
    }
  }

  @override
  Future<void> saveUser({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    values['auth_user_id'] = userId;
    values['auth_user_email'] = email;
    values['auth_user_display_name'] = displayName ?? '';
  }

  @override
  Future<Map<String, String>?> getCachedUser() async {
    final userId = values['auth_user_id'];
    final email = values['auth_user_email'];
    if (userId == null || email == null) return null;
    final displayName = values['auth_user_display_name'];
    return <String, String>{
      'id': userId,
      'email': email,
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
    };
  }

  @override
  Future<String?> getAccessToken() async => values['access_token'];

  @override
  Future<String?> getRefreshToken() async => values['refresh_token'];

  @override
  Future<void> clearTokens() async {
    values.remove('access_token');
    values.remove('refresh_token');
    values.remove('auth_user_id');
    values.remove('auth_user_email');
    values.remove('auth_user_display_name');
  }

  @override
  Future<String?> readRaw(String key) async => values[key];

  @override
  Future<void> writeRaw(String key, String value) async {
    values[key] = value;
  }
}

/// Data bundle used by the screen-level tests. All providers are overridden so
/// no screen ever reaches the network or Drift.
class QaHarness {
  QaHarness({Map<String, dynamic>? authProfile, bool authenticated = true})
      : storage = QaFakeSecureStorage(authenticated: authenticated) {
    adapter = QaFakeHttpClientAdapter(authProfile: authProfile);
    dio = Dio(BaseOptions(baseUrl: 'https://qa.kasyaba.test/api/v1'))
      ..httpClientAdapter = adapter;
  }

  final QaFakeSecureStorage storage;
  late final QaFakeHttpClientAdapter adapter;
  late final Dio dio;

  /// Overrides required to keep every platform boundary silent.
  List<Override> get baseOverrides => <Override>[
        dioProvider.overrideWithValue(dio),
        secureStorageProvider.overrideWithValue(storage),
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            dio,
            storage,
            const Stream<void>.empty(),
          ),
        ),
        pendingSyncTransactionsProvider.overrideWith(
          (ref) => Stream<List<OfflineTransaction>>.value(
            const <OfflineTransaction>[],
          ),
        ),
      ];

  /// Pumps [screen] inside a themed MaterialApp and verifies a clean layout.
  ///
  /// Defaults to [ThemeMode.dark] so every pre-LT-A widget test keeps its
  /// existing appearance.
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    List<Override> overrides = const <Override>[],
    // The Flutter test font renders every glyph ~1em wide, which is much wider
    // than DM Sans on a real phone. A wide viewport isolates genuine layout
    // bugs from those test-font artifacts (matching the repo's existing widget
    // tests). Clearance tests pin the 812px height separately.
    Size viewport = const Size(800, 1600),
    bool settle = true,
    TextScaler? textScaler,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...baseOverrides,
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme().light,
          darkTheme: AppTheme().dark,
          themeMode: themeMode,
          builder: textScaler == null
              ? null
              : (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: textScaler,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
          home: screen,
        ),
      ),
    );

    if (settle) {
      await qaSettle(tester);
    } else {
      await tester.pump();
    }
  }
}

/// Convenience alias for pumping a widget under a specific [ThemeMode].
Future<void> qaPumpWithTheme(
  WidgetTester tester,
  Widget widget,
  ThemeMode mode, {
  QaHarness? harness,
  List<Override> overrides = const <Override>[],
  Size viewport = const Size(800, 1600),
  bool settle = true,
  TextScaler? textScaler,
}) {
  return (harness ?? QaHarness()).pumpScreen(
    tester,
    widget,
    overrides: overrides,
    viewport: viewport,
    settle: settle,
    textScaler: textScaler,
    themeMode: mode,
  );
}

/// Settles all pending frames and fails the test on any Flutter error
/// (including RenderFlex overflow) that surfaced during the pump.
Future<void> qaSettle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    timeout,
  );
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: 'Unexpected Flutter error while pumping (overflow/build crash): '
        '$exception',
  );
}

/// Asserts the scaffolded sheet chrome: exactly one [AppSheet] and none of the
/// legacy 36/38 x 4 hand-drawn drag handles inside it.
void qaExpectAppSheetChrome(WidgetTester tester) {
  expect(
    find.byType(AppSheet),
    findsOneWidget,
    reason: 'Migrated sheet must render exactly one shared AppSheet chrome.',
  );

  final containers = tester.widgetList<Container>(
    find.descendant(
      of: find.byType(AppSheet),
      matching: find.byType(Container),
    ),
  );
  final legacyHandles = containers.where((container) {
    final constraints = container.constraints;
    if (constraints == null || !constraints.isTight) return false;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final isLegacyWidth = width == 36.0 || width == 38.0;
    final isHandleHeight = height == 4.0 || height == 5.0;
    return isLegacyWidth && isHandleHeight;
  }).toList();

  expect(
    legacyHandles,
    isEmpty,
    reason: 'Legacy hand-drawn drag handle is still rendered inside AppSheet.',
  );
}

/// Returns the padding of the outermost ListView / SingleChildScrollView.
EdgeInsets qaPrimaryScrollablePadding(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is ListView || widget is SingleChildScrollView,
  );
  final widgets = tester.widgetList<Widget>(finder).toList();
  expect(
    widgets,
    isNotEmpty,
    reason: 'Screen has no ListView / SingleChildScrollView to inspect.',
  );

  final primary = widgets.first;
  final EdgeInsetsGeometry? padding;
  if (primary is ListView) {
    padding = primary.padding;
  } else if (primary is SingleChildScrollView) {
    padding = primary.padding;
  } else {
    padding = null;
  }
  expect(
    padding,
    isA<EdgeInsets>(),
    reason: 'Primary scrollable must expose concrete EdgeInsets padding.',
  );
  return padding! as EdgeInsets;
}

/// Asserts the primary scrollable keeps the dock clearance token at the bottom.
void qaExpectDockClearance(WidgetTester tester) {
  final padding = qaPrimaryScrollablePadding(tester);
  expect(
    padding.bottom,
    KasyabaTokens.dockClearance,
    reason: 'Primary scrollable bottom padding must equal the dock clearance '
        'token (${KasyabaTokens.dockClearance}).',
  );
}

const Account qaDefaultAccount = Account(
  id: qaAccountId,
  name: 'Cash Wallet',
  type: 'cash',
);

UserProfile qaDefaultProfile({double? salaryAmount, String? displayName}) {
  return UserProfile(
    id: qaTestUserId,
    email: qaTestEmail,
    displayName: displayName ?? 'QA User',
    salaryAmount: salaryAmount,
    paydayFrequency: 'semi-monthly',
    paydaySchedule: '15th & 30th',
    minimumBalanceThreshold: 0,
  );
}

const DashboardData qaDefaultDashboard = DashboardData(
  totalBalance: 12345.67,
  income: 5000,
  expenses: 1000,
  savings: 500,
  healthScore: 'Good',
  predictedMonthEnd: 11000,
  budgetUsedPercent: 25,
  categoryExpenses: <CategoryExpenseSummary>[],
  dailyBalance: <DailyBalancePoint>[],
);

PlanningOverview qaDefaultPlanningOverview() {
  final now = DateTime.now();
  return PlanningOverview(
    from: now,
    to: now.add(const Duration(days: 14)),
    currentBalance: 12345.67,
    minimumBalanceThreshold: 0,
    totalPlannedIncome: 0,
    totalPlannedExpenses: 0,
    totalUpcomingBills: 0,
    projectedClosingBalance: 12345.67,
    availableBuffer: 12345.67,
    safeToSpendPerDay: 880,
    daysInWindow: 14,
    status: 'clear',
    calculationNote: 'QA fixture',
    days: const <PlanningDay>[],
  );
}

/// A complete, deterministic set of financial providers for screen mounts.
List<Override> qaDefaultDataOverrides({
  UserProfile? profile,
  List<Account>? accounts,
  Map<String, double>? balances,
  List<BillItem>? bills,
  List<SavingsGoal>? goals,
  List<AlertItem>? alerts,
  DashboardData? dashboard,
  PlanningOverview? planning,
  List<TransactionEntry>? transactions,
}) {
  final resolvedProfile = profile ?? qaDefaultProfile();
  const resolvedAccounts = <Account>[qaDefaultAccount];
  final resolvedBalances =
      balances ?? const <String, double>{qaAccountId: 12345.67};
  final resolvedBills = bills ?? const <BillItem>[];
  final resolvedGoals = goals ?? const <SavingsGoal>[];
  final resolvedAlerts = alerts ?? const <AlertItem>[];
  final resolvedDashboard = dashboard ?? qaDefaultDashboard;
  final resolvedTransactions =
      transactions ?? const <TransactionEntry>[];

  return <Override>[
    userProfileProvider.overrideWith((ref) async => resolvedProfile),
    accountsProvider.overrideWith((ref) async => accounts ?? resolvedAccounts),
    accountBalancesProvider.overrideWith((ref) async => resolvedBalances),
    billsProvider.overrideWith((ref) async => resolvedBills),
    goalsProvider.overrideWith((ref) async => resolvedGoals),
    alertsProvider.overrideWith((ref) async => resolvedAlerts),
    dashboardProvider.overrideWith((ref) async => resolvedDashboard),
    budgetStatusProvider.overrideWith((ref) async => BudgetStatus.empty()),
    categoriesProvider.overrideWith((ref) async => defaultCategoriesList),
    transactionsProvider.overrideWith((ref) async => resolvedTransactions),
    paginatedTransactionsProvider.overrideWith(
      (ref) async => PaginatedTransactions(
        items: resolvedTransactions,
        page: 1,
        limit: 50,
        totalCount: resolvedTransactions.length,
      ),
    ),
    planningProvider.overrideWith(
      (ref) async => planning ?? qaDefaultPlanningOverview(),
    ),
  ];
}

/// A minimal host that opens a sheet using the pressed button context.
class QaSheetLauncher extends StatelessWidget {
  const QaSheetLauncher({
    super.key,
    required this.label,
    required this.onLaunch,
  });

  final String label;
  final void Function(BuildContext context) onLaunch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KasyabaTokens.ebony,
      body: Center(
        child: ElevatedButton(
          onPressed: () => onLaunch(context),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Taps [finder], scrolling the primary scroll view until it is visible first.
Future<void> qaTapVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = 250,
}) async {
  if (finder.evaluate().isEmpty) {
    fail('Cannot tap: target widget was not found.');
  }
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
