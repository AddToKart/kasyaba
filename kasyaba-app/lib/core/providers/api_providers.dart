import 'dart:async';
import '../database/cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../auth/auth_provider.dart';

part 'api_providers.freezed.dart';
part 'api_providers.g.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

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

String _categoryKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _categoryNamesMatch(String left, String right) {
  final a = _categoryKey(left);
  final b = _categoryKey(right);
  return a == b || a.startsWith(b) || b.startsWith(a);
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
  final response = await dio.get('/accounts');
  final data = response.data['data'] as List<dynamic>;
  return data.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
});

final accountBalancesProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final dio = ref.watch(dioProvider);
  final accounts = await ref.watch(accountsProvider.future);
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
  try {
    final response = await dio.get('/expense-categories');
    final data = response.data['data'] as List<dynamic>;
    var categories = data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
    if (categories.isEmpty) {
      return defaultCategoriesList;
    }
    return categories;
  } catch (_) {
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
    // Update cache with fresh data (fire-and-forget)
    unawaited(cacheService.cacheDashboard(data, userId).catchError((_) {}));
    return data;
  } catch (e) {
    // Try cached data as fallback
    final cached = await cacheService.getCachedDashboard(userId);
    if (cached != null) return cached.copyWith(isFromCache: true);
    throw StateError('Dashboard data is unavailable. Please try again.');
  }
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

  bool get isTransfer => type == 'transfer';
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

  try {
    final response = await dio.get('/transactions', queryParameters: params);
    final rawItems = response.data['data'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((raw) => raw as Map<String, dynamic>)
        .map((item) {
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
        })
        .toList();
    final totalCount =
        (response.data['meta']?['total'] as num?)?.toInt() ?? items.length;

    return PaginatedTransactions(
      items: items,
      page: filter.page,
      limit: filter.limit,
      totalCount: totalCount,
    );
  } catch (_) {
    rethrow;
  }
});

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
  try {
    final res = await dio.get('/goals');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    rethrow;
  }
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
  }) = _BillItem;

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return _BillItem(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      dueDate:
          DateTime.tryParse(json['dueDate']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'upcoming',
    );
  }
}

final billsProvider = FutureProvider<List<BillItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    // 500 is the server-side maximum; bills are bounded to avoid unbounded
    // history payloads as paid instances accumulate.
    final res = await dio.get('/bills', queryParameters: {'limit': 500});
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => BillItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
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

    final realCategoryId = await _resolveCategoryId(
      categoryId: categoryId,
      categoryName: categoryName,
    );

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
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    var status = TransactionSaveStatus.saved;
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
    final realCategoryId = await _resolveCategoryId(categoryId: categoryId);
    await _dio.patch('/expenses/$id', data: {
      'accountId': accountId,
      'categoryId': realCategoryId,
      'amount': amount.toStringAsFixed(2),
      'description': description,
      'spentAt': _dateOnlyPayload(spentAt),
      'status': _statusForDate(spentAt),
      'notes': notes ?? '',
    });
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
    await _dio.patch('/income/$id', data: {
      'accountId': accountId,
      'amount': amount.toStringAsFixed(2),
      'source': source,
      'receivedAt': _dateOnlyPayload(receivedAt),
      'status': _statusForDate(receivedAt),
      'notes': notes ?? '',
    });
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
      await _ref.read(cacheServiceProvider).queueTransaction(
        type: 'transfer',
        userId: userId,
        data: data,
      );
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
    await _dio.post('/accounts', data: {
      'name': name.trim(),
      'type': type,
      'openingBalance': openingBalance.toStringAsFixed(2),
      'currencyCode': 'PHP',
    });
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
  }

  Future<void> archiveAccount(String accountId) async {
    await _dio.post('/accounts/$accountId/archive');
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
  }

  void _afterTransactionMutation() {
    _ref.invalidate(dashboardProvider);
    _invalidateTransactionProviders();
    _ref.invalidate(alertsProvider);
    _ref.invalidate(recoveryAnalysisProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _ref.invalidate(planningProvider);
    _ref.invalidate(budgetStatusProvider);
    _ref.invalidate(goalsProvider);
    _ref.invalidate(billsProvider);
  }

  Future<String> _resolveCategoryId({
    required String categoryId,
    String? categoryName,
  }) async {
    if (_uuidPattern.hasMatch(categoryId)) return categoryId;

    try {
      final response = await _dio.get('/expense-categories');
      final categories = (response.data['data'] as List<dynamic>?) ?? [];
      final desiredName = categoryName?.trim();

      for (final raw in categories) {
        final category = raw as Map<String, dynamic>;
        final id = category['id']?.toString();
        final name = category['name']?.toString();
        if (id != null &&
            _uuidPattern.hasMatch(id) &&
            desiredName != null &&
            name != null &&
            _categoryNamesMatch(desiredName, name)) {
          return id;
        }
      }

      if (desiredName == null || desiredName.isEmpty) {
        throw StateError('Choose an expense category first.');
      }

      final createResponse = await _dio.post(
        '/expense-categories',
        data: {'name': desiredName, 'iconKey': 'receipt'},
      );
      final createdId = createResponse.data['data']?['id']?.toString();
      if (createdId == null || !_uuidPattern.hasMatch(createdId)) {
        throw StateError('The selected expense category is unavailable.');
      }
      return createdId;
    } on DioException {
      throw StateError(
        'Expense categories are unavailable. Try again when online.',
      );
    }
  }

  void _invalidateTransactionProviders() {
    _ref.invalidate(paginatedTransactionsProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final data = {
      'name': name,
      'targetAmount': targetAmount.toStringAsFixed(2),
      if (targetDate != null) 'targetDate': _dateOnlyPayload(targetDate),
    };

    await _dio.post('/goals', data: data);

    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
  }

  Future<void> addGoalContribution({
    required String goalId,
    required double amount,
    String? accountId,
    String? notes,
  }) async {
    final data = {
      'amount': amount.toStringAsFixed(2),
      if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
      // UTC ISO-8601 with an explicit Z so the server stores the correct
      // instant regardless of its own timezone.
      'contributedAt': DateTime.now().toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'clientMutationId': const Uuid().v4(),
    };

    await _dio.post('/goals/$goalId/contributions', data: data);

    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _ref.invalidate(paginatedTransactionsProvider);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(planningProvider);
  }

  Future<void> addBill({
    required String name,
    required double amount,
    required DateTime startsOn,
    String recurrence = 'monthly',
  }) async {
    final data = {
      'name': name,
      'defaultAmount': amount.toStringAsFixed(2),
      'startsOn': _dateOnlyPayload(startsOn),
      'recurrence': recurrence,
    };

    await _dio.post('/bill-templates', data: data);

    _ref.invalidate(billsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(planningProvider);
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
  }

  Future<void> markBillUnpaid(String billId) async {
    await _dio.post('/bills/$billId/mark-unpaid');
    _ref.invalidate(billsProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountBalancesProvider);
    _invalidateTransactionProviders();
    _ref.invalidate(planningProvider);
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
  try {
    final res = await dio.get('/alerts', queryParameters: {'status': 'unread'});
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    rethrow;
  }
});

// -----------------------------------------------------------------------------
// Financial Recovery Analysis Models & Provider
// -----------------------------------------------------------------------------
class RootCauseItem {
  final String title;
  final String description;
  final String severity;

  RootCauseItem({
    required this.title,
    required this.description,
    required this.severity,
  });

  factory RootCauseItem.fromJson(Map<String, dynamic> json) => RootCauseItem(
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    severity: json['severity']?.toString() ?? 'info',
  );
}

class ActionStepItem {
  final int stepNumber;
  final String title;
  final String description;
  final String icon;

  ActionStepItem({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory ActionStepItem.fromJson(Map<String, dynamic> json) => ActionStepItem(
    stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 1,
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    icon: json['icon']?.toString() ?? 'check',
  );
}

class RecoveryAnalysis {
  final int healthScore;
  final String healthGrade;
  final String summaryMessage;
  final List<RootCauseItem> rootCauses;
  final double recommendedDailySpendLimit;
  final int daysRemainingInMonth;
  final double safeLiquidCash;
  final String? estimatedRecoveryDate;
  final List<ActionStepItem> actionSteps;

  RecoveryAnalysis({
    required this.healthScore,
    required this.healthGrade,
    required this.summaryMessage,
    required this.rootCauses,
    required this.recommendedDailySpendLimit,
    required this.daysRemainingInMonth,
    required this.safeLiquidCash,
    this.estimatedRecoveryDate,
    required this.actionSteps,
  });

  factory RecoveryAnalysis.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return RecoveryAnalysis(
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
      healthGrade: json['healthGrade']?.toString() ?? 'Needs Attention',
      summaryMessage: json['summaryMessage']?.toString() ?? '',
      rootCauses:
          (json['rootCauses'] as List<dynamic>?)
              ?.map((e) => RootCauseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendedDailySpendLimit: parseNum(json['recommendedDailySpendLimit']),
      daysRemainingInMonth:
          (json['daysRemainingInMonth'] as num?)?.toInt() ?? 1,
      safeLiquidCash: parseNum(json['safeLiquidCash']),
      estimatedRecoveryDate: json['estimatedRecoveryDate']?.toString(),
      actionSteps:
          (json['actionSteps'] as List<dynamic>?)
              ?.map((e) => ActionStepItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

final recoveryAnalysisProvider = FutureProvider<RecoveryAnalysis>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get('/alerts/analysis');
    return RecoveryAnalysis.fromJson(res.data['data'] as Map<String, dynamic>);
  } catch (_) {
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
  final now = DateTime.now();
  final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  try {
    final res = await dio.get(
      '/budgets/status',
      queryParameters: {'month': monthStr},
    );
    return BudgetStatus.fromJson(res.data['data'] as Map<String, dynamic>);
  } catch (_) {
    rethrow;
  }
});
