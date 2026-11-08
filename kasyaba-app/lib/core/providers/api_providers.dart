import 'dart:async';
import 'dart:convert';
import '../database/cache_service.dart';
import '../database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../api/category_resolver.dart';
import '../auth/auth_provider.dart';
import '../connectivity/connectivity_service.dart';

part 'api_providers.freezed.dart';
part 'api_providers.g.dart';

/// Reads a snapshot defensively so a device-storage failure can never mask the
/// original network error a provider is already handling.
Future<String?> _readSnapshot(
  CacheService cacheService,
  String userId,
  String key,
) async {
  try {
    final snapshot = await cacheService.getSnapshot(userId, key);
    return snapshot?.json;
  } catch (_) {
    return null;
  }
}

String _dateOnlyPayload(DateTime date) {
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

DateTime _parseTransactionDate(dynamic value) {
  final raw = value?.toString() ?? '';
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
  if (match != null) {
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }
  return DateTime.tryParse(raw) ?? DateTime.now();
}

// -----------------------------------------------------------------------------
// Financial Account Model & Provider
// -----------------------------------------------------------------------------
@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required String name,
    @Default('cash') String type,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  try {
    final response = await dio.get('/accounts');
    final data = response.data['data'] as List<dynamic>;
    if (userId != null) {
      unawaited(
        cacheService
            .putSnapshot(
              userId: userId,
              key: CacheService.snapshotKeyAccounts,
              json: jsonEncode(data),
            )
            .catchError((_) {}),
      );
    }
    return data
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    final snapshot = userId == null
        ? null
        : await _readSnapshot(
            cacheService,
            userId,
            CacheService.snapshotKeyAccounts,
          );
    if (snapshot != null) {
      try {
        final data = jsonDecode(snapshot) as List<dynamic>;
        return data
            .map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    rethrow;
  }
});

final accountBalancesProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final accounts = await ref.watch(accountsProvider.future);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  final map = <String, double>{};
  await Future.wait(
    accounts.map((acc) async {
      try {
        final res = await dio.get('/accounts/${acc.id}/balance');
        final val = res.data['data']?['balance'];
        if (val != null) {
          map[acc.id] = double.tryParse(val.toString()) ?? 0.0;
        }
      } catch (_) {}
    }),
  );

  // If every per-account call failed (offline / endpoint unreachable), serve
  // the last-known balances so wallets keep their amounts, per the privacy
  // policy's device-cache list.
  if (map.isEmpty && accounts.isNotEmpty && userId != null) {
    try {
      final snapshot = await cacheService.getSnapshot(
        userId,
        CacheService.snapshotKeyBalances,
      );
      if (snapshot != null) {
        final decoded = jsonDecode(snapshot.json) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final amount = double.tryParse(value?.toString() ?? '');
          if (amount != null) {
            map[key] = amount;
          }
        });
      }
    } catch (_) {}
  }

  // Persist the fetched (network-path) balances before the pending-overlay
  // deltas are applied, so offline fallbacks never double-count them.
  if (userId != null && map.isNotEmpty) {
    try {
      await cacheService.putSnapshot(
        userId: userId,
        key: CacheService.snapshotKeyBalances,
        json: jsonEncode(map),
      );
    } catch (_) {}
  }

  // If there are pending local offline transactions, apply their net effect
  if (userId != null) {
    try {
      final pending = await cacheService.getAllOfflineTransactions(userId);
      for (final tx in pending) {
        try {
          final payload = jsonDecode(tx.json) as Map<String, dynamic>;
          final amount =
              double.tryParse(payload['amount']?.toString() ?? '0') ?? 0.0;

          final dateStr =
              (payload['spentAt'] ??
                      payload['receivedAt'] ??
                      payload['transferredAt'])
                  ?.toString();
          final txDate = dateStr != null
              ? DateTime.tryParse(dateStr) ?? tx.createdAt
              : tx.createdAt;
          final txDay = DateTime(txDate.year, txDate.month, txDate.day);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isPosted =
              payload['status'] != 'planned' && !txDay.isAfter(today);

          if (!isPosted) continue;

          if (tx.type == 'expense') {
            final accId = payload['accountId']?.toString();
            if (accId != null && map.containsKey(accId)) {
              map[accId] = (map[accId] ?? 0.0) - amount;
            }
          } else if (tx.type == 'income') {
            final accId = payload['accountId']?.toString();
            if (accId != null && map.containsKey(accId)) {
              map[accId] = (map[accId] ?? 0.0) + amount;
            }
          } else if (tx.type == 'transfer') {
            final fromId = payload['fromAccountId']?.toString();
            final toId = payload['toAccountId']?.toString();
            if (fromId != null && map.containsKey(fromId)) {
              map[fromId] = (map[fromId] ?? 0.0) - amount;
            }
            if (toId != null && map.containsKey(toId)) {
              map[toId] = (map[toId] ?? 0.0) + amount;
            }
          } else if (tx.type == 'goal_contribution') {
            // A queued goal deposit is funded from a wallet, so it lowers that
            // wallet's balance even before the server replays the contribution.
            final accId = payload['accountId']?.toString();
            if (accId != null && map.containsKey(accId)) {
              map[accId] = (map[accId] ?? 0.0) - amount;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  return map;
});

/// Ensures the user has at least one account after signing in. Kept out of
/// [accountsProvider] so a read can never mutate data: previously an offline
/// list request failed just because the auto-create POST could not run.
final accountBootstrapProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    final justAuthenticated =
        next.isAuthenticated &&
        (previous?.isAuthenticated != true || previous?.userId != next.userId);
    if (justAuthenticated) unawaited(_ensureDefaultAccount(ref));
  }, fireImmediately: true);
});

Future<void> _ensureDefaultAccount(Ref ref) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/accounts');
    final data = response.data['data'] as List<dynamic>? ?? const [];
    if (data.isNotEmpty) return;

    await dio.post(
      '/accounts',
      data: {
        'name': 'Cash Wallet',
        'type': 'cash',
        'openingBalance': '0.00',
        'currencyCode': 'PHP',
      },
    );
    ref.invalidate(accountsProvider);
  } catch (_) {
    // Best effort: the user can still create an account from Accounts.
  }
}

// -----------------------------------------------------------------------------
// Expense Category Model & Provider
// -----------------------------------------------------------------------------
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    @Default('receipt') String iconKey,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

final List<Category> defaultCategoriesList = [
  Category(id: 'cat_food', name: 'Food & Dining', iconKey: 'restaurant'),
  Category(
    id: 'cat_transport',
    name: 'Transportation',
    iconKey: 'directions_car',
  ),
  Category(id: 'cat_utilities', name: 'Utilities & Bills', iconKey: 'bolt'),
  Category(id: 'cat_rent', name: 'Rent & Housing', iconKey: 'home'),
  Category(id: 'cat_education', name: 'Education', iconKey: 'school'),
  Category(id: 'cat_healthcare', name: 'Healthcare', iconKey: 'local_hospital'),
  Category(id: 'cat_entertainment', name: 'Entertainment', iconKey: 'movie'),
  Category(id: 'cat_shopping', name: 'Shopping', iconKey: 'shopping_cart'),
  Category(id: 'cat_other', name: 'Other', iconKey: 'receipt'),
];

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  try {
    final response = await dio.get('/expense-categories');
    final data = response.data['data'] as List<dynamic>;
    if (userId != null) {
      unawaited(
        cacheService
            .putSnapshot(
              userId: userId,
              key: CacheService.snapshotKeyCategories,
              json: jsonEncode(data),
            )
            .catchError((_) {}),
      );
    }
    var categories = data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
    if (categories.isEmpty) {
      return defaultCategoriesList;
    }
    return categories;
  } catch (_) {
    final snapshot = userId == null
        ? null
        : await _readSnapshot(
            cacheService,
            userId,
            CacheService.snapshotKeyCategories,
          );
    if (snapshot != null) {
      try {
        final data = jsonDecode(snapshot) as List<dynamic>;
        final categories = data
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
        return categories.isEmpty ? defaultCategoriesList : categories;
      } catch (_) {}
    }
    rethrow;
  }
});

// -----------------------------------------------------------------------------
// Dashboard Data Model & Provider
// -----------------------------------------------------------------------------
@freezed
class CategoryExpenseSummary with _$CategoryExpenseSummary {
  const factory CategoryExpenseSummary({
    @Default('Other') String categoryName,
    @Default('receipt') String iconKey,
    @Default(0.0) double total,
  }) = _CategoryExpenseSummary;

  factory CategoryExpenseSummary.fromJson(Map<String, dynamic> json) {
    return _CategoryExpenseSummary(
      categoryName: json['categoryName']?.toString() ?? 'Other',
      iconKey: json['iconKey']?.toString() ?? 'receipt',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }
}

extension CategoryExpenseSummaryJson on CategoryExpenseSummary {
  Map<String, dynamic> toJson() => {
    'categoryName': categoryName,
    'iconKey': iconKey,
    'total': total.toStringAsFixed(2),
  };
}

@freezed
class DailyBalancePoint with _$DailyBalancePoint {
  const factory DailyBalancePoint({
    required String date,
    required double balance,
    double? projected,
  }) = _DailyBalancePoint;

  factory DailyBalancePoint.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return DailyBalancePoint(
      date: json['date']?.toString() ?? '',
      balance: parseNum(json['balance']),
      projected: json['predictedEnd'] != null
          ? parseNum(json['predictedEnd'])
          : (json['projected'] != null ? parseNum(json['projected']) : null),
    );
  }
}

extension DailyBalancePointJson on DailyBalancePoint {
  Map<String, dynamic> toJson() => {
    'date': date,
    'balance': balance,
    'predictedEnd': projected,
  };
}

@freezed
class DashboardData with _$DashboardData {
  const factory DashboardData({
    required double totalBalance,
    required double income,
    required double expenses,
    required double savings,
    required String healthScore,
    required double predictedMonthEnd,
    @Default(0.0) double budgetUsedPercent,
    required List<CategoryExpenseSummary> categoryExpenses,
    @Default([]) List<DailyBalancePoint> dailyBalance,
    @Default(0.0) double projectedIncome,
    @Default(0.0) double projectedExpenses,
    @Default('medium') String confidence,
    @Default(false) bool isFromCache,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    List<CategoryExpenseSummary> cats = [];
    if (json['charts'] != null &&
        json['charts']['expensesByCategory'] is List) {
      cats = (json['charts']['expensesByCategory'] as List)
          .map(
            (e) => CategoryExpenseSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }

    List<DailyBalancePoint> dailyBalance = [];
    if (json['charts'] != null && json['charts']['dailyBalance'] is List) {
      dailyBalance = (json['charts']['dailyBalance'] as List)
          .map((e) => DailyBalancePoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    String healthScore = 'Good';
    if (json['healthGrade'] != null) {
      healthScore = json['healthGrade'].toString();
    } else if (json['healthScore'] != null) {
      final score = parseNum(json['healthScore']);
      if (score >= 85) {
        healthScore = 'Excellent';
      } else if (score >= 70) {
        healthScore = 'Good';
      } else if (score >= 50) {
        healthScore = 'Fair';
      } else {
        healthScore = 'Needs Attention';
      }
    }

    return _DashboardData(
      totalBalance: parseNum(
        json['balance'] ?? json['actualBalance'] ?? json['currentBalance'],
      ),
      income: parseNum(
        json['income'] ??
            json['incomeMonthToDate'] ??
            json['monthToDateIncome'],
      ),
      expenses: parseNum(
        json['expenses'] ??
            json['expensesMonthToDate'] ??
            json['monthToDateExpenses'],
      ),
      savings: parseNum(json['savings'] ?? json['savingsMonthToDate']),
      healthScore: healthScore,
      predictedMonthEnd: parseNum(
        json['predictedMonthEndBalance'] ?? json['predictedBalance'],
      ),
      budgetUsedPercent: parseNum(json['budgetUsedPercent']),
      categoryExpenses: cats,
      dailyBalance: dailyBalance,
      projectedIncome: parseNum(
        json['projectedMonthEndIncome'] ?? json['projectedIncome'],
      ),
      projectedExpenses: parseNum(
        json['projectedMonthEndExpenses'] ?? json['projectedExpenses'],
      ),
      confidence: json['confidence']?.toString() ?? 'medium',
      isFromCache: false,
    );
  }
}

extension DashboardDataJson on DashboardData {
  Map<String, dynamic> toJson() => {
    'balance': totalBalance.toStringAsFixed(2),
    'income': income.toStringAsFixed(2),
    'expenses': expenses.toStringAsFixed(2),
    'savings': savings.toStringAsFixed(2),
    'healthGrade': healthScore,
    'predictedMonthEndBalance': predictedMonthEnd.toStringAsFixed(2),
    'projectedMonthEndIncome': projectedIncome.toStringAsFixed(2),
    'projectedMonthEndExpenses': projectedExpenses.toStringAsFixed(2),
    'confidence': confidence,
    'budgetUsedPercent': budgetUsedPercent,
    'charts': {
      'expensesByCategory': categoryExpenses.map((c) => c.toJson()).toList(),
      'dailyBalance': dailyBalance.map((d) => d.toJson()).toList(),
    },
  };
}

// -----------------------------------------------------------------------------
// Manual Planning Lab Model & Provider
// -----------------------------------------------------------------------------
class PlanningDay {
  final DateTime date;
  final double income;
  final double expenses;
  final double bills;
  final double net;
  final double projectedBalance;
  final String pressure;

  const PlanningDay({
    required this.date,
    required this.income,
    required this.expenses,
    required this.bills,
    required this.net,
    required this.projectedBalance,
    required this.pressure,
  });

  factory PlanningDay.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    return PlanningDay(
      date: _parseTransactionDate(json['date']),
      income: parseNum(json['income']),
      expenses: parseNum(json['expenses']),
      bills: parseNum(json['bills']),
      net: parseNum(json['net']),
      projectedBalance: parseNum(json['projectedBalance']),
      pressure: json['pressure']?.toString() ?? 'clear',
    );
  }
}

class PlanningOverview {
  final DateTime from;
  final DateTime to;
  final double currentBalance;
  final double minimumBalanceThreshold;
  final double totalPlannedIncome;
  final double totalPlannedExpenses;
  final double totalUpcomingBills;
  final double projectedClosingBalance;
  final double availableBuffer;
  final double safeToSpendPerDay;
  final int daysInWindow;
  final String status;
  final String calculationNote;
  final List<PlanningDay> days;

  const PlanningOverview({
    required this.from,
    required this.to,
    required this.currentBalance,
    required this.minimumBalanceThreshold,
    required this.totalPlannedIncome,
    required this.totalPlannedExpenses,
    required this.totalUpcomingBills,
    required this.projectedClosingBalance,
    required this.availableBuffer,
    required this.safeToSpendPerDay,
    required this.daysInWindow,
    required this.status,
    required this.calculationNote,
    required this.days,
  });

  double get committedOutflow => totalPlannedExpenses + totalUpcomingBills;

  factory PlanningOverview.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    final rawDays = json['days'] as List<dynamic>? ?? [];
    return PlanningOverview(
      from: _parseTransactionDate(json['from']),
      to: _parseTransactionDate(json['to']),
      currentBalance: parseNum(json['currentBalance']),
      minimumBalanceThreshold: parseNum(json['minimumBalanceThreshold']),
      totalPlannedIncome: parseNum(json['totalPlannedIncome']),
      totalPlannedExpenses: parseNum(json['totalPlannedExpenses']),
      totalUpcomingBills: parseNum(json['totalUpcomingBills']),
      projectedClosingBalance: parseNum(json['projectedClosingBalance']),
      availableBuffer: parseNum(json['availableBuffer']),
      safeToSpendPerDay: parseNum(json['safeToSpendPerDay']),
      daysInWindow: (json['daysInWindow'] as num?)?.toInt() ?? rawDays.length,
      status: json['status']?.toString() ?? 'clear',
      calculationNote: json['calculationNote']?.toString() ?? '',
      days: rawDays
          .whereType<Map<String, dynamic>>()
          .map(PlanningDay.fromJson)
          .toList(),
    );
  }
}

final planningProvider = FutureProvider<PlanningOverview>((ref) async {
  final dio = ref.watch(dioProvider);
  // Let the backend choose the window from the user's saved timezone. This
  // prevents the phone's local timezone from shifting the planning dates.
  final response = await dio.get('/planning/overview');
  return PlanningOverview.fromJson(
    response.data['data'] as Map<String, dynamic>,
  );
});

DashboardData applyPendingOfflineMutations(
  DashboardData baseData,
  List<OfflineTransaction> pending,
) {
  if (pending.isEmpty) return baseData;
  var balanceDelta = 0.0;
  var expenseDelta = 0.0;
  var incomeDelta = 0.0;
  var predictedExpenseDelta = 0.0;
  var predictedIncomeDelta = 0.0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final tx in pending) {
    try {
      final payload = jsonDecode(tx.json) as Map<String, dynamic>;
      final amount =
          double.tryParse(payload['amount']?.toString() ?? '0') ?? 0.0;

      final dateStr =
          (payload['spentAt'] ??
                  payload['receivedAt'] ??
                  payload['transferredAt'])
              ?.toString();
      final txDate = dateStr != null
          ? DateTime.tryParse(dateStr) ?? tx.createdAt
          : tx.createdAt;
      final txDay = DateTime(txDate.year, txDate.month, txDate.day);
      final isPosted = payload['status'] != 'planned' && !txDay.isAfter(today);

      if (tx.type == 'expense') {
        predictedExpenseDelta += amount;
        if (isPosted) {
          balanceDelta -= amount;
          expenseDelta += amount;
        }
      } else if (tx.type == 'income') {
        predictedIncomeDelta += amount;
        if (isPosted) {
          balanceDelta += amount;
          incomeDelta += amount;
        }
      }
    } catch (_) {}
  }

  final newBalance = baseData.totalBalance + balanceDelta;
  final newExpenses = baseData.expenses + expenseDelta;
  final newIncome = baseData.income + incomeDelta;
  final newPredicted =
      baseData.predictedMonthEnd + predictedIncomeDelta - predictedExpenseDelta;

  return baseData.copyWith(
    totalBalance: newBalance,
    expenses: newExpenses,
    income: newIncome,
    predictedMonthEnd: newPredicted,
    isFromCache: true,
  );
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  if (userId == null) {
    throw StateError('You must be signed in to load dashboard data.');
  }

  try {
    final response = await dio.get('/dashboard');
    final data = DashboardData.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
    // Update the unified snapshot store with fresh data (fire-and-forget).
    unawaited(
      cacheService
          .putSnapshot(
            userId: userId,
            key: CacheService.snapshotKeyDashboard,
            json: jsonEncode(data.toJson()),
          )
          .catchError((_) {}),
    );

    final pending = await cacheService.getAllOfflineTransactions(userId);
    if (pending.isNotEmpty) {
      return applyPendingOfflineMutations(data, pending);
    }
    return data;
  } catch (e) {
    // Try the unified snapshot store as fallback.
    final snapshot = await _readSnapshot(
      cacheService,
      userId,
      CacheService.snapshotKeyDashboard,
    );
    if (snapshot != null) {
      try {
        final cached = DashboardData.fromJson(
          jsonDecode(snapshot) as Map<String, dynamic>,
        );
        final pending = await cacheService.getAllOfflineTransactions(userId);
        return applyPendingOfflineMutations(
          cached.copyWith(isFromCache: true),
          pending,
        );
      } catch (_) {}
    }
    throw StateError('Dashboard data is unavailable. Please try again.');
  }
});

/// Fetched-at timestamp for a cached snapshot key, or null when no snapshot
/// exists. UI uses this to surface cache age without changing value types.
final cachedSnapshotMetaProvider = FutureProvider.family<DateTime?, String>((
  ref,
  key,
) async {
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  if (userId == null) return null;
  try {
    final snapshot = await cacheService.getSnapshot(userId, key);
    return snapshot?.fetchedAt;
  } catch (_) {
    return null;
  }
});

final pendingSyncTransactionsProvider =
    StreamProvider<List<OfflineTransaction>>((ref) {
      final cacheService = ref.watch(cacheServiceProvider);
      final userId = ref.watch(authProvider).userId;
      if (userId == null) return const Stream.empty();
      return cacheService.watchPendingSyncTransactions(userId);
    });

final pendingSyncCountProvider = Provider<int>((ref) {
  final pending = ref.watch(pendingSyncTransactionsProvider).valueOrNull ?? [];
  return pending.length;
});

// -----------------------------------------------------------------------------
// Transaction Entry Model & List Provider
// -----------------------------------------------------------------------------
@freezed
class TransactionEntry with _$TransactionEntry {
  const factory TransactionEntry({
    required String id,
    required String title,
    required double amount,
    required bool isExpense,
    required DateTime date,
    required String categoryName,
    @Default('expense') String type,
    @Default('posted') String status,
    String? accountId,
    String? categoryId,
    String? notes,
  }) = _TransactionEntry;

  factory TransactionEntry.fromJson(Map<String, dynamic> json) =>
      _$TransactionEntryFromJson(json);
}

extension TransactionEntryStatus on TransactionEntry {
  bool get isScheduled {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    return status == 'planned' &&
        dateOnly.isAfter(DateTime(today.year, today.month, today.day));
  }

  bool get isCancelled => status == 'cancelled';

  bool get isPendingSync => status == 'pending_sync';

  bool get isSyncFailed => status == 'sync_failed';

  bool get isTransfer => type == 'transfer';
}

TransactionEntry offlineTransactionToEntry(OfflineTransaction ot) {
  final isFailed = ot.failedAt != null;
  try {
    final data = jsonDecode(ot.json) as Map<String, dynamic>;
    final type = ot.type;
    final isExpense = type == 'expense';
    final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
    final dateStr =
        (data['spentAt'] ?? data['receivedAt'] ?? data['transferredAt'])
            ?.toString();
    final date = dateStr != null
        ? DateTime.tryParse(dateStr) ?? ot.createdAt
        : ot.createdAt;
    final title = isExpense
        ? ((data['description'] != null &&
                  data['description'].toString().isNotEmpty)
              ? data['description'].toString()
              : (data['merchant']?.toString() ??
                    (data['notes']?.toString() ??
                        (isFailed ? 'Failed Expense' : 'Expense'))))
        : (type == 'income'
              ? ((data['source'] != null &&
                        data['source'].toString().isNotEmpty)
                    ? data['source'].toString()
                    : (data['notes']?.toString() ??
                          (isFailed ? 'Failed Income' : 'Income')))
              : (isFailed ? 'Failed Transfer' : 'Transfer'));
    final categoryName = isExpense
        ? (data['categoryName']?.toString() ??
              (isFailed ? 'Sync Failed' : 'Pending Sync'))
        : (type == 'income' ? 'Income' : 'Transfer');
    return TransactionEntry(
      id: ot.id,
      title: title.isNotEmpty
          ? title
          : (isFailed ? 'Failed Entry' : 'Pending Offline Entry'),
      amount: amount,
      isExpense: isExpense,
      date: date,
      categoryName: categoryName,
      type: type,
      status: isFailed ? 'sync_failed' : 'pending_sync',
      accountId:
          data['accountId']?.toString() ?? data['fromAccountId']?.toString(),
      categoryId: data['categoryId']?.toString(),
      notes: isFailed
          ? (ot.lastError ?? 'Failed to sync')
          : data['notes']?.toString(),
    );
  } catch (_) {
    return TransactionEntry(
      id: ot.id,
      title: isFailed ? 'Sync Failed' : 'Pending Sync',
      amount: 0.0,
      isExpense: ot.type == 'expense',
      date: ot.createdAt,
      categoryName: isFailed ? 'Sync Failed' : 'Offline',
      type: ot.type,
      status: isFailed ? 'sync_failed' : 'pending_sync',
      notes: isFailed ? ot.lastError : null,
    );
  }
}

class TransactionQueryFilter {
  final int page;
  final int limit;
  final DateTime? fromDate;
  final DateTime? toDate;

  const TransactionQueryFilter({
    this.page = 1,
    this.limit = 10,
    this.fromDate,
    this.toDate,
  });

  TransactionQueryFilter copyWith({
    int? page,
    int? limit,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDates = false,
  }) {
    return TransactionQueryFilter(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
    );
  }
}

class PaginatedTransactions {
  final List<TransactionEntry> items;
  final int page;
  final int limit;
  final int totalCount;

  const PaginatedTransactions({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalCount,
  });

  int get totalPages => (totalCount / limit).ceil().clamp(1, 9999);
  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;
}

final transactionFilterProvider = StateProvider<TransactionQueryFilter>((ref) {
  return const TransactionQueryFilter(page: 1, limit: 50);
});

final paginatedTransactionsProvider = FutureProvider<PaginatedTransactions>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final filter = ref.watch(transactionFilterProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  final pending = userId != null
      ? await cacheService.getAllOfflineTransactions(userId)
      : <OfflineTransaction>[];
  final pendingEntries = pending.map(offlineTransactionToEntry).toList();

  final Map<String, dynamic> params = {
    'page': filter.page,
    'limit': filter.limit,
  };
  if (filter.fromDate != null) {
    params['from'] = filter.fromDate!.toIso8601String().split('T')[0];
  }
  if (filter.toDate != null) {
    params['to'] = filter.toDate!.toIso8601String().split('T')[0];
  }

  final snapshotKey = CacheService.transactionsKey(
    page: filter.page,
    from: filter.fromDate,
    to: filter.toDate,
  );

  try {
    final response = await dio.get('/transactions', queryParameters: params);
    final rawItems = response.data['data'] as List<dynamic>? ?? [];
    final items = rawItems.map((raw) => raw as Map<String, dynamic>).map((
      item,
    ) {
      final type = item['type']?.toString() ?? 'expense';
      return TransactionEntry(
        id: item['id']?.toString() ?? '',
        title: item['title']?.toString() ?? 'Transaction',
        amount: double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
        isExpense: type == 'expense',
        date: _parseTransactionDate(item['date']),
        categoryName: item['categoryName']?.toString() ?? 'Transaction',
        type: type,
        status: item['status']?.toString() ?? 'posted',
        accountId: item['accountId']?.toString(),
        categoryId: item['categoryId']?.toString(),
        notes: item['notes']?.toString(),
      );
    }).toList();
    final totalCount =
        (response.data['meta']?['total'] as num?)?.toInt() ?? items.length;

    if (userId != null) {
      unawaited(
        cacheService
            .putSnapshot(
              userId: userId,
              key: snapshotKey,
              json: jsonEncode({
                'items': items.map((entry) => entry.toJson()).toList(),
                'totalCount': totalCount,
              }),
            )
            .catchError((_) {}),
      );
    }

    final filteredPendingEntries = filter.page == 1
        ? _filterPendingEntries(pendingEntries, filter)
        : const <TransactionEntry>[];

    final combinedItems = filter.page == 1
        ? [...filteredPendingEntries, ...items]
        : items;

    return PaginatedTransactions(
      items: combinedItems,
      page: filter.page,
      limit: filter.limit,
      totalCount: totalCount + filteredPendingEntries.length,
    );
  } catch (_) {
    final snapshot = userId == null
        ? null
        : await _readSnapshot(cacheService, userId, snapshotKey);
    if (snapshot != null) {
      try {
        final decoded = jsonDecode(snapshot) as Map<String, dynamic>;
        final cachedItems = (decoded['items'] as List<dynamic>? ?? [])
            .map(
              (raw) => TransactionEntry.fromJson(raw as Map<String, dynamic>),
            )
            .toList();
        final cachedTotal =
            (decoded['totalCount'] as num?)?.toInt() ?? cachedItems.length;
        final filteredPendingEntries = filter.page == 1
            ? _filterPendingEntries(pendingEntries, filter)
            : const <TransactionEntry>[];
        return PaginatedTransactions(
          items: filter.page == 1
              ? [...filteredPendingEntries, ...cachedItems]
              : cachedItems,
          page: filter.page,
          limit: filter.limit,
          totalCount: cachedTotal + filteredPendingEntries.length,
        );
      } catch (_) {}
    }

    if (pendingEntries.isNotEmpty && filter.page == 1) {
      final filteredPendingEntries = _filterPendingEntries(
        pendingEntries,
        filter,
      );
      return PaginatedTransactions(
        items: filteredPendingEntries,
        page: 1,
        limit: filter.limit,
        totalCount: filteredPendingEntries.length,
      );
    }
    rethrow;
  }
});

List<TransactionEntry> _filterPendingEntries(
  List<TransactionEntry> pendingEntries,
  TransactionQueryFilter filter,
) {
  return pendingEntries.where((entry) {
    final entryDay = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    );
    if (filter.fromDate != null) {
      final from = filter.fromDate!;
      final fromDay = DateTime(from.year, from.month, from.day);
      if (entryDay.isBefore(fromDay)) return false;
    }
    if (filter.toDate != null) {
      final to = filter.toDate!;
      final toDay = DateTime(to.year, to.month, to.day);
      if (entryDay.isAfter(toDay)) return false;
    }
    return true;
  }).toList();
}

final transactionsProvider = FutureProvider<List<TransactionEntry>>((
  ref,
) async {
  final paginated = await ref.watch(paginatedTransactionsProvider.future);
  return paginated.items;
});

// -----------------------------------------------------------------------------
// Savings Goals Model & Provider
// -----------------------------------------------------------------------------
@freezed
class SavingsGoal with _$SavingsGoal {
  const SavingsGoal._();

  const factory SavingsGoal({
    required String id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    String? targetDate,
    bool? canAffordByTargetDate,
    String? earliestAffordableDate,
    double? monthlySavingsRequired,
    int? daysRemaining,
  }) = _SavingsGoal;

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return _SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: parseNum(json['targetAmount']),
      currentAmount: parseNum(json['currentAmount'] ?? json['savedAmount']),
      targetDate: json['targetDate']?.toString(),
      canAffordByTargetDate: json['canAffordByTargetDate'] as bool?,
      earliestAffordableDate: json['earliestAffordableDate']?.toString(),
      monthlySavingsRequired: json['monthlySavingsRequired'] != null
          ? parseNum(json['monthlySavingsRequired'])
          : null,
      daysRemaining: json['daysRemaining'] is int
          ? json['daysRemaining'] as int
          : (json['daysRemaining'] != null
                ? int.tryParse(json['daysRemaining'].toString())
                : null),
    );
  }
}

final goalsProvider = FutureProvider<List<SavingsGoal>>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  try {
    final res = await dio.get('/goals');
    final data = res.data['data'] as List<dynamic>;
    if (userId != null) {
      unawaited(
        cacheService
            .putSnapshot(
              userId: userId,
              key: CacheService.snapshotKeyGoals,
              json: jsonEncode(data),
            )
            .catchError((_) {}),
      );
    }
    return data
        .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    final snapshot = userId == null
        ? null
        : await _readSnapshot(
            cacheService,
            userId,
            CacheService.snapshotKeyGoals,
          );
    if (snapshot != null) {
      try {
        final data = jsonDecode(snapshot) as List<dynamic>;
        return data
            .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    rethrow;
  }
});

final goalDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, goalId) async {
      final dio = ref.watch(dioProvider);
      final res = await dio.get('/goals/$goalId');
      return res.data['data'] as Map<String, dynamic>;
    });

// -----------------------------------------------------------------------------
// Bills Model & Provider
// -----------------------------------------------------------------------------
@freezed
class BillItem with _$BillItem {
  const factory BillItem({
    required String id,
    required String name,
    required double amount,
    required DateTime dueDate,
    @Default('upcoming') String status,
    String? categoryId,
    String? recurrence,
    @Default(1) int reminderLeadDays,
  }) = _BillItem;

  factory BillItem.fromJson(Map<String, dynamic> json) {
    final template = json['template'] as Map<String, dynamic>?;
    return _BillItem(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      dueDate:
          DateTime.tryParse(json['dueDate']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'upcoming',
      categoryId:
          json['categoryId']?.toString() ?? template?['categoryId']?.toString(),
      recurrence:
          json['recurrence']?.toString() ?? template?['recurrence']?.toString(),
      reminderLeadDays:
          (json['reminderLeadDays'] as num?)?.toInt() ??
          (template?['reminderLeadDays'] as num?)?.toInt() ??
          1,
    );
  }
}

final billsProvider = FutureProvider<List<BillItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  try {
    // 500 is the server-side maximum; bills are bounded to avoid unbounded
    // history payloads as paid instances accumulate.
    final res = await dio.get('/bills', queryParameters: {'limit': 500});
    final data = res.data['data'] as List<dynamic>;
    if (userId != null) {
      unawaited(
        cacheService
            .putSnapshot(
              userId: userId,
              key: CacheService.snapshotKeyBills,
              json: jsonEncode(data),
            )
            .catchError((_) {}),
      );
    }
    return data
        .map((e) => BillItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    final snapshot = userId == null
        ? null
        : await _readSnapshot(
            cacheService,
            userId,
            CacheService.snapshotKeyBills,
          );
    if (snapshot != null) {
      try {
        final data = jsonDecode(snapshot) as List<dynamic>;
        return data
            .map((e) => BillItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    rethrow;
  }
});

// -----------------------------------------------------------------------------
// Add Transaction API Mutator
// -----------------------------------------------------------------------------
enum TransactionSaveStatus { saved, queued }

class TransactionMutator {
  final Dio _dio;
  final Ref _ref;

  TransactionMutator(this._dio, this._ref);

  static const _uuid = Uuid();

  String _currentUserId() {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) {
      throw StateError('You must be signed in to save financial data.');
    }
    return userId;
  }

  bool _canQueue(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  String _statusForDate(DateTime date) {
    final selected = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    return selected.isAfter(current) ? 'planned' : 'posted';
  }

  Future<TransactionSaveStatus> addExpense({
    required String accountId,
    required String categoryId,
    String? categoryName,
    required double amount,
    required String description,
    required DateTime spentAt,
    String? notes,
  }) async {
    final cacheService = _ref.read(cacheServiceProvider);
    final userId = _currentUserId();

    var realCategoryId = categoryId;
    var queueDirectly = false;

    if (!isCategoryUuid(categoryId)) {
      // Offline: never attempt the online-only name → UUID lookup. The queue
      // keeps the display name and a placeholder id; replay resolves it.
      if (!_ref.read(isOnlineProvider)) {
        queueDirectly = true;
      } else {
        try {
          realCategoryId = await resolveCategoryId(
            dio: _dio,
            categoryId: categoryId,
            categoryName: categoryName,
          );
        } on CategoryResolutionException catch (error) {
          if (!error.queueable ||
              categoryName == null ||
              categoryName.trim().isEmpty) {
            rethrow;
          }
          queueDirectly = true;
        }
      }
    }

    final formattedAmount = amount.toStringAsFixed(2);
    final dateIso = _dateOnlyPayload(spentAt);
    final data = {
      'accountId': accountId,
      'categoryId': realCategoryId,
      'amount': formattedAmount,
      'description': description,
      'spentAt': dateIso,
      'status': _statusForDate(spentAt),
      'clientMutationId': _uuid.v4(),
      if (categoryName != null && categoryName.isNotEmpty)
        'categoryName': categoryName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    var status = TransactionSaveStatus.saved;
    if (queueDirectly) {
      await cacheService.queueTransaction(
        type: 'expense',
        userId: userId,
        data: data,
      );
      status = TransactionSaveStatus.queued;
    } else {
      try {
        await _dio.post('/expenses', data: data);
      } on DioException catch (error) {
        if (!_canQueue(error)) rethrow;
        await cacheService.queueTransaction(
          type: 'expense',
          userId: userId,
          data: data,
        );
        status = TransactionSaveStatus.queued;
      }
    }

    _afterTransactionMutation();
    return status;
  }

  Future<TransactionSaveStatus> addIncome({
    required String accountId,
    required double amount,
    required String source,
    required DateTime receivedAt,
    String? notes,
  }) async {
    final cacheService = _ref.read(cacheServiceProvider);
    final userId = _currentUserId();

    final formattedAmount = amount.toStringAsFixed(2);
    final dateIso = _dateOnlyPayload(receivedAt);
    final data = {
      'accountId': accountId,
      'amount': formattedAmount,
      'source': source,
      'receivedAt': dateIso,
      'status': _statusForDate(receivedAt),
      'clientMutationId': _uuid.v4(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    var status = TransactionSaveStatus.saved;
    try {
      await _dio.post('/income', data: data);
    } on DioException catch (error) {
      if (!_canQueue(error)) rethrow;
      await cacheService.queueTransaction(
        type: 'income',
        userId: userId,
        data: data,
      );
      status = TransactionSaveStatus.queued;
    }

    _afterTransactionMutation();
    return status;
  }

  Future<void> updateExpense({
    required String id,
    required String accountId,
    required String categoryId,
    required double amount,
    required String description,
    required DateTime spentAt,
    String? notes,
  }) async {
    final realCategoryId = await resolveCategoryId(
      dio: _dio,
      categoryId: categoryId,
    );
    await _dio.patch(
      '/expenses/$id',
      data: {
        'accountId': accountId,
        'categoryId': realCategoryId,
        'amount': amount.toStringAsFixed(2),
        'description': description,
        'spentAt': _dateOnlyPayload(spentAt),
        'status': _statusForDate(spentAt),
        'notes': notes ?? '',
      },
    );
    _afterTransactionMutation();
  }

  Future<void> updateIncome({
    required String id,
    required String accountId,
    required double amount,
    required String source,
    required DateTime receivedAt,
    String? notes,
  }) async {
    await _dio.patch(
      '/income/$id',
      data: {
        'accountId': accountId,
        'amount': amount.toStringAsFixed(2),
        'source': source,
        'receivedAt': _dateOnlyPayload(receivedAt),
        'status': _statusForDate(receivedAt),
        'notes': notes ?? '',
      },
    );
    _afterTransactionMutation();
  }

  Future<void> deleteTransaction(TransactionEntry transaction) async {
    final path = transaction.isTransfer
        ? '/transfers/${transaction.id}'
        : transaction.isExpense
        ? '/expenses/${transaction.id}'
        : '/income/${transaction.id}';
    await _dio.delete(path);
    _afterTransactionMutation();
  }

  Future<TransactionSaveStatus> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime transferredAt,
    String? notes,
  }) async {
    if (fromAccountId == toAccountId) {
      throw StateError('Choose two different accounts for a transfer.');
    }
    final userId = _currentUserId();
    final data = {
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount.toStringAsFixed(2),
      'transferredAt': _dateOnlyPayload(transferredAt),
      'status': _statusForDate(transferredAt),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'clientMutationId': _uuid.v4(),
    };
    var saveStatus = TransactionSaveStatus.saved;
    try {
      await _dio.post('/transfers', data: data);
    } on DioException catch (error) {
      if (!_canQueue(error)) rethrow;
      await _ref
          .read(cacheServiceProvider)
          .queueTransaction(type: 'transfer', userId: userId, data: data);
      saveStatus = TransactionSaveStatus.queued;
    }
    _afterTransactionMutation();
    return saveStatus;
  }

  Future<void> createAccount({
    required String name,
    required String type,
    double openingBalance = 0,
  }) async {
    await _dio.post(
      '/accounts',
      data: {
        'name': name.trim(),
        'type': type,
        'openingBalance': openingBalance.toStringAsFixed(2),
        'currencyCode': 'PHP',
      },
    );
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(alertsProvider);
  }

  Future<void> archiveAccount(String accountId) async {
    await _dio.post('/accounts/$accountId/archive');
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(alertsProvider);
  }

  Future<void> createBudget({
    required double amount,
    required DateTime startsOn,
    String? categoryId,
    DateTime? endsOn,
    bool isActive = true,
  }) async {
    await _dio.post(
      '/budgets',
      data: {
        'amount': amount.toStringAsFixed(2),
        'startsOn': _dateOnlyPayload(startsOn),
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (endsOn != null) 'endsOn': _dateOnlyPayload(endsOn),
        'isActive': isActive,
      },
    );
    _ref.invalidate(budgetStatusProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(alertsProvider);
  }

  Future<void> deleteBudget(String budgetId) async {
    await _dio.delete('/budgets/$budgetId');
    _ref.invalidate(budgetStatusProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(alertsProvider);
  }

  void _afterTransactionMutation() {
    _ref.invalidate(dashboardProvider);
    _invalidateTransactionProviders();
    _ref.invalidate(alertsProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(budgetStatusProvider);
    _ref.invalidate(goalsProvider);
    _ref.invalidate(billsProvider);
  }

  void _invalidateTransactionProviders() {
    _ref.invalidate(paginatedTransactionsProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<SavingsGoal?> addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final data = {
      'name': name,
      'targetAmount': targetAmount.toStringAsFixed(2),
      if (targetDate != null) 'targetDate': _dateOnlyPayload(targetDate),
    };

    final response = await _dio.post('/goals', data: data);
    final created = response.data['data'];
    final SavingsGoal? createdGoal = created is Map<String, dynamic>
        ? SavingsGoal.fromJson(created)
        : null;

    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(alertsProvider);
    return createdGoal;
  }

  Future<void> updateGoal({
    required String goalId,
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final data = {
      'name': name,
      'targetAmount': targetAmount.toStringAsFixed(2),
      if (targetDate != null) 'targetDate': _dateOnlyPayload(targetDate),
    };

    await _dio.patch('/goals/$goalId', data: data);

    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(goalDetailProvider(goalId));
    _ref.invalidate(alertsProvider);
  }

  Future<void> deleteGoal(String goalId) async {
    await _dio.delete('/goals/$goalId');

    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(goalDetailProvider(goalId));
    _ref.invalidate(alertsProvider);
  }

  Future<void> addGoalContribution({
    required String goalId,
    required double amount,
    String? accountId,
    String? notes,
  }) async {
    final cacheService = _ref.read(cacheServiceProvider);
    final userId = _currentUserId();
    final data = {
      'goalId': goalId,
      'amount': amount.toStringAsFixed(2),
      if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
      // UTC ISO-8601 with an explicit Z so the server stores the correct
      // instant regardless of its own timezone.
      'contributedAt': DateTime.now().toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'clientMutationId': _uuid.v4(),
    };
    final body = Map<String, dynamic>.from(data)..remove('goalId');

    try {
      await _dio.post('/goals/$goalId/contributions', data: body);
    } on DioException catch (error) {
      if (!_canQueue(error)) rethrow;
      await cacheService.queueTransaction(
        type: 'goal_contribution',
        userId: userId,
        data: data,
      );
    }

    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _ref.invalidate(paginatedTransactionsProvider);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(goalDetailProvider(goalId));
    _ref.invalidate(alertsProvider);
  }

  Future<void> addBill({
    required String name,
    required double amount,
    required DateTime startsOn,
    String recurrence = 'monthly',
    String? categoryId,
    int reminderLeadDays = 1,
  }) async {
    final normalizedRecurrence = recurrence.toLowerCase() == 'once'
        ? 'none'
        : recurrence.toLowerCase();

    final data = <String, dynamic>{
      'name': name,
      'defaultAmount': amount.toStringAsFixed(2),
      'startsOn': _dateOnlyPayload(startsOn),
      'recurrence': normalizedRecurrence,
      if (normalizedRecurrence == 'monthly') 'dayOfMonth': startsOn.day,
      if (normalizedRecurrence == 'weekly') 'dayOfWeek': startsOn.weekday % 7,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      'reminderLeadDays': reminderLeadDays,
    };

    await _dio.post('/bill-templates', data: data);

    _ref.invalidate(billsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(alertsProvider);
  }

  Future<void> markBillPaid({
    required String billId,
    required String accountId,
  }) async {
    await _dio.post('/bills/$billId/mark-paid', data: {'accountId': accountId});
    _ref.invalidate(billsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _invalidateTransactionProviders();
    _ref.invalidate(planningProvider);
    _ref.invalidate(budgetStatusProvider);
    _ref.invalidate(goalsProvider);
    _ref.invalidate(alertsProvider);
  }

  Future<void> markBillUnpaid(String billId) async {
    await _dio.post('/bills/$billId/mark-unpaid');
    _ref.invalidate(billsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _invalidateTransactionProviders();
    _ref.invalidate(planningProvider);
    _ref.invalidate(budgetStatusProvider);
    _ref.invalidate(goalsProvider);
    _ref.invalidate(alertsProvider);
  }

  Future<void> updateProfile({
    String? displayName,
    double? salaryAmount,
    String? paydayFrequency,
    String? paydaySchedule,
    double? minimumBalanceThreshold,
  }) async {
    final data = {
      'displayName': ?displayName,
      'salaryAmount': ?salaryAmount?.toStringAsFixed(2),
      'paydayFrequency': ?paydayFrequency,
      'paydaySchedule': ?paydaySchedule,
      'minimumBalanceThreshold': ?minimumBalanceThreshold?.toStringAsFixed(2),
    };
    await _dio.patch('/auth/me', data: data);
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(alertsProvider);
  }

  Future<PurchaseCheckResult> evaluatePurchaseCheck({
    required String itemTitle,
    required double amount,
  }) async {
    final res = await _dio.post(
      '/forecasting/purchase-check',
      data: {'itemTitle': itemTitle, 'amount': amount},
    );
    return PurchaseCheckResult.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }
}

final transactionMutatorProvider = Provider<TransactionMutator>((ref) {
  final dio = ref.watch(dioProvider);
  return TransactionMutator(dio, ref);
});

final budgetRepositoryProvider = transactionMutatorProvider;

// -----------------------------------------------------------------------------
// User Profile & Purchase Checker Models & Providers
// -----------------------------------------------------------------------------
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    String? displayName,
    double? salaryAmount,
    String? paydayFrequency,
    String? paydaySchedule,
    double? minimumBalanceThreshold,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    double? parseOptNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return _UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName']?.toString(),
      salaryAmount: parseOptNum(json['salaryAmount']),
      paydayFrequency: json['paydayFrequency']?.toString() ?? 'semi-monthly',
      paydaySchedule: json['paydaySchedule']?.toString() ?? '15th & 30th',
      minimumBalanceThreshold: parseOptNum(json['minimumBalanceThreshold']),
    );
  }
}

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get('/auth/me');
    return UserProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  } catch (_) {
    rethrow;
  }
});

class GoalImpactItem {
  final String goalName;
  final String? originalTargetDate;
  final String? delayedTargetDate;
  final int delayDays;

  const GoalImpactItem({
    required this.goalName,
    this.originalTargetDate,
    this.delayedTargetDate,
    required this.delayDays,
  });

  factory GoalImpactItem.fromJson(Map<String, dynamic> json) {
    return GoalImpactItem(
      goalName: json['goalName']?.toString() ?? 'Savings Goal',
      originalTargetDate: json['originalTargetDate']?.toString(),
      delayedTargetDate: json['delayedTargetDate']?.toString(),
      delayDays: (json['delayDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class PurchaseCheckResult {
  final String itemTitle;
  final double amount;
  final String verdict;
  final String statusTitle;
  final String statusMessage;
  final double currentBalance;
  final double postPurchaseBalance;
  final double projectedMonthEndBalance;
  final double postPurchaseMonthEndBalance;
  final double totalUpcomingBills;
  final double cashAfterBills;
  final String? earliestSafeBuyDate;
  final int? daysUntilSafeBuy;
  final List<String> reasons;
  final List<GoalImpactItem> goalImpacts;

  PurchaseCheckResult({
    required this.itemTitle,
    required this.amount,
    required this.verdict,
    required this.statusTitle,
    required this.statusMessage,
    required this.currentBalance,
    required this.postPurchaseBalance,
    required this.projectedMonthEndBalance,
    required this.postPurchaseMonthEndBalance,
    required this.totalUpcomingBills,
    required this.cashAfterBills,
    this.earliestSafeBuyDate,
    this.daysUntilSafeBuy,
    required this.reasons,
    this.goalImpacts = const [],
  });

  factory PurchaseCheckResult.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return PurchaseCheckResult(
      itemTitle: json['itemTitle']?.toString() ?? 'Intended Purchase',
      amount: parseNum(json['amount']),
      verdict: json['verdict']?.toString() ?? 'AFFORDABLE',
      statusTitle: json['statusTitle']?.toString() ?? 'Evaluated Purchase',
      statusMessage: json['statusMessage']?.toString() ?? '',
      currentBalance: parseNum(json['currentBalance']),
      postPurchaseBalance: parseNum(json['postPurchaseBalance']),
      projectedMonthEndBalance: parseNum(json['projectedMonthEndBalance']),
      postPurchaseMonthEndBalance: parseNum(
        json['postPurchaseMonthEndBalance'],
      ),
      totalUpcomingBills: parseNum(json['totalUpcomingBills']),
      cashAfterBills: parseNum(json['cashAfterBills']),
      earliestSafeBuyDate: json['earliestSafeBuyDate']?.toString(),
      daysUntilSafeBuy: json['daysUntilSafeBuy'] is int
          ? json['daysUntilSafeBuy'] as int
          : (json['daysUntilSafeBuy'] != null
                ? int.tryParse(json['daysUntilSafeBuy'].toString())
                : null),
      reasons:
          (json['reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      goalImpacts:
          (json['goalImpacts'] as List<dynamic>?)
              ?.map((e) => GoalImpactItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// -----------------------------------------------------------------------------
// Financial Alerts Model & Provider
// -----------------------------------------------------------------------------
@freezed
class AlertItem with _$AlertItem {
  const factory AlertItem({
    required String id,
    required String type,
    required String severity,
    required String title,
    required String message,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _AlertItem;

  factory AlertItem.fromJson(Map<String, dynamic> json) =>
      _$AlertItemFromJson(json);
}

extension AlertItemRead on AlertItem {
  bool get isRead => readAt != null;
}

final alertsProvider = FutureProvider<List<AlertItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  try {
    final res = await dio.get('/alerts');
    final data = res.data['data'] as List<dynamic>;
    if (userId != null) {
      unawaited(
        cacheService
            .putSnapshot(
              userId: userId,
              key: CacheService.snapshotKeyAlerts,
              json: jsonEncode(data),
            )
            .catchError((_) {}),
      );
    }
    return data
        .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    final snapshot = userId == null
        ? null
        : await _readSnapshot(
            cacheService,
            userId,
            CacheService.snapshotKeyAlerts,
          );
    if (snapshot != null) {
      try {
        final data = jsonDecode(snapshot) as List<dynamic>;
        return data
            .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    rethrow;
  }
});

// -----------------------------------------------------------------------------
// Budget Status Model & Provider
// -----------------------------------------------------------------------------
@freezed
class BudgetItemStatus with _$BudgetItemStatus {
  const factory BudgetItemStatus({
    @Default('') String budgetId,
    String? categoryId,
    @Default(0.0) double amount,
    @Default(0.0) double spent,
    @Default(0.0) double remaining,
    @Default(0.0) double percentUsed,
    @Default('on_track') String status,
  }) = _BudgetItemStatus;

  factory BudgetItemStatus.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return _BudgetItemStatus(
      budgetId: json['budgetId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      amount: parseNum(json['amount']),
      spent: parseNum(json['spent']),
      remaining: parseNum(json['remaining']),
      percentUsed: parseNum(json['percentUsed']),
      status: json['status']?.toString() ?? 'on_track',
    );
  }
}

@freezed
class BudgetStatus with _$BudgetStatus {
  const factory BudgetStatus({
    @Default('') String month,
    @Default(0.0) double totalBudget,
    @Default(0.0) double totalSpent,
    @Default(0.0) double overallPercent,
    @Default(0) int budgetCount,
    required List<BudgetItemStatus> budgets,
  }) = _BudgetStatus;

  factory BudgetStatus.empty() => _BudgetStatus(budgets: []);

  factory BudgetStatus.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return _BudgetStatus(
      month: json['month']?.toString() ?? '',
      totalBudget: parseNum(json['totalBudget']),
      totalSpent: parseNum(json['totalSpent']),
      overallPercent: parseNum(json['overallPercent']),
      budgetCount: (json['budgetCount'] as num?)?.toInt() ?? 0,
      budgets:
          (json['budgets'] as List<dynamic>?)
              ?.map((e) => BudgetItemStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

final budgetStatusProvider = FutureProvider<BudgetStatus>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final userId = ref.watch(authProvider).userId;
  final now = DateTime.now();
  final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  try {
    final res = await dio.get(
      '/budgets/status',
      queryParameters: {'month': monthStr},
    );
    final data = res.data['data'] as Map<String, dynamic>;
    if (userId != null) {
      unawaited(
        cacheService
            .putSnapshot(
              userId: userId,
              key: CacheService.snapshotKeyBudgets,
              json: jsonEncode(data),
            )
            .catchError((_) {}),
      );
    }
    return BudgetStatus.fromJson(data);
  } catch (_) {
    final snapshot = userId == null
        ? null
        : await _readSnapshot(
            cacheService,
            userId,
            CacheService.snapshotKeyBudgets,
          );
    if (snapshot != null) {
      try {
        return BudgetStatus.fromJson(
          jsonDecode(snapshot) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    rethrow;
  }
});
