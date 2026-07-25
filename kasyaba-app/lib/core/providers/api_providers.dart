import 'dart:async';
import '../database/cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../api/api_client.dart';

part 'api_providers.freezed.dart';
part 'api_providers.g.dart';

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

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/accounts');
    final data = response.data['data'] as List<dynamic>;
    var accounts = data.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
    if (accounts.isEmpty) {
      // Auto-create default Cash account if none exists
      final createRes = await dio.post('/accounts', data: {
        'name': 'Cash Wallet',
        'type': 'cash',
        'openingBalance': '0.00',
        'currencyCode': 'PHP',
      });
      final created = Account.fromJson(createRes.data['data'] as Map<String, dynamic>);
      accounts = [created];
    }
    return accounts;
  } catch (e) {
    return [Account(id: 'default', name: 'Cash Wallet', type: 'cash')];
  }
});

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

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}

final List<Category> defaultCategoriesList = [
  Category(id: 'cat_food', name: 'Food & Dining', iconKey: 'restaurant'),
  Category(id: 'cat_transport', name: 'Transportation', iconKey: 'directions_car'),
  Category(id: 'cat_utilities', name: 'Utilities & Bills', iconKey: 'bolt'),
  Category(id: 'cat_rent', name: 'Rent & Housing', iconKey: 'home'),
  Category(id: 'cat_education', name: 'Education', iconKey: 'school'),
  Category(id: 'cat_shopping', name: 'Shopping', iconKey: 'shopping_cart'),
  Category(id: 'cat_other', name: 'Other', iconKey: 'receipt'),
];

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/expense-categories');
    final data = response.data['data'] as List<dynamic>;
    var categories = data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    if (categories.isEmpty) {
      return defaultCategoriesList;
    }
    return categories;
  } catch (e) {
    return defaultCategoriesList;
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
    required List<CategoryExpenseSummary> categoryExpenses,
    @Default([]) List<DailyBalancePoint> dailyBalance,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    List<CategoryExpenseSummary> cats = [];
    if (json['charts'] != null && json['charts']['expensesByCategory'] is List) {
      cats = (json['charts']['expensesByCategory'] as List)
          .map((e) => CategoryExpenseSummary.fromJson(e as Map<String, dynamic>))
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
      if (score >= 80) {
        healthScore = 'Excellent';
      } else if (score >= 60) {
        healthScore = 'Good';
      } else if (score >= 50) {
        healthScore = 'Fair';
      } else {
        healthScore = 'Needs Attention';
      }
    }

    return _DashboardData(
      totalBalance: parseNum(json['balance'] ?? json['actualBalance'] ?? json['currentBalance']),
      income: parseNum(json['income'] ?? json['incomeMonthToDate'] ?? json['monthToDateIncome']),
      expenses: parseNum(json['expenses'] ?? json['expensesMonthToDate'] ?? json['monthToDateExpenses']),
      savings: parseNum(json['savings'] ?? json['savingsMonthToDate']),
      healthScore: healthScore,
      predictedMonthEnd: parseNum(json['predictedMonthEndBalance'] ?? json['predictedBalance']),
      categoryExpenses: cats,
      dailyBalance: dailyBalance,
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
    'charts': {
      'expensesByCategory': categoryExpenses.map((c) => c.toJson()).toList(),
      'dailyBalance': dailyBalance.map((d) => d.toJson()).toList(),
    },
  };
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  try {
    final response = await dio.get('/dashboard');
    final data = DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
    // Update cache with fresh data (fire-and-forget)
    unawaited(cacheService.cacheDashboard(data));
    return data;
  } catch (e) {
    // Try cached data as fallback
    final cached = await cacheService.getCachedDashboard();
    if (cached != null) return cached;
    return DashboardData(
      totalBalance: 0.0,
      income: 0.0,
      expenses: 0.0,
      savings: 0.0,
      healthScore: 'Good',
      predictedMonthEnd: 0.0,
      categoryExpenses: [],
    );
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
  }) = _TransactionEntry;

  factory TransactionEntry.fromJson(Map<String, dynamic> json) => _$TransactionEntryFromJson(json);
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
  return const TransactionQueryFilter(page: 1, limit: 10);
});

final paginatedTransactionsProvider = FutureProvider<PaginatedTransactions>((ref) async {
  final dio = ref.watch(dioProvider);
  final filter = ref.watch(transactionFilterProvider);
  final List<TransactionEntry> items = [];

  final Map<String, dynamic> params = {};
  if (filter.fromDate != null) {
    params['from'] = filter.fromDate!.toIso8601String().split('T')[0];
  }
  if (filter.toDate != null) {
    params['to'] = filter.toDate!.toIso8601String().split('T')[0];
  }

  try {
    // Fetch Expenses
    final expRes = await dio.get('/expenses', queryParameters: params);
    final expData = expRes.data['data'] as List<dynamic>;
    for (final item in expData) {
      items.add(TransactionEntry(
        id: item['id'],
        title: item['description'] ?? 'Expense',
        amount: double.tryParse(item['amount'].toString()) ?? 0.0,
        isExpense: true,
        date: DateTime.parse(item['spentAt'] ?? DateTime.now().toIso8601String()),
        categoryName: item['category']?['name'] ?? 'Expense',
      ));
    }

    // Fetch Income
    final incRes = await dio.get('/income', queryParameters: params);
    final incData = incRes.data['data'] as List<dynamic>;
    for (final item in incData) {
      items.add(TransactionEntry(
        id: item['id'],
        title: item['source'] ?? 'Income',
        amount: double.tryParse(item['amount'].toString()) ?? 0.0,
        isExpense: false,
        date: DateTime.parse(item['receivedAt'] ?? DateTime.now().toIso8601String()),
        categoryName: 'Income',
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
  } catch (_) {}

  final totalCount = items.length;
  final startIndex = (filter.page - 1) * filter.limit;
  final paginatedItems = items.skip(startIndex).take(filter.limit).toList();

  return PaginatedTransactions(
    items: paginatedItems,
    page: filter.page,
    limit: filter.limit,
    totalCount: totalCount,
  );
});

final transactionsProvider = FutureProvider<List<TransactionEntry>>((ref) async {
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

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

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
          : (json['daysRemaining'] != null ? int.tryParse(json['daysRemaining'].toString()) : null),
    );
  }
}

final goalsProvider = FutureProvider<List<SavingsGoal>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get('/goals');
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
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
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'upcoming',
    );
  }
}

final billsProvider = FutureProvider<List<BillItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get('/bills');
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => BillItem.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

// -----------------------------------------------------------------------------
// Add Transaction API Mutator
// -----------------------------------------------------------------------------
class TransactionMutator {
  final Dio _dio;
  final Ref _ref;

  TransactionMutator(this._dio, this._ref);

  Future<void> addExpense({
    required String accountId,
    required String categoryId,
    required double amount,
    required String description,
    required DateTime spentAt,
    String? notes,
  }) async {
    final cacheService = _ref.read(cacheServiceProvider);

    String realCategoryId = categoryId;

    if (categoryId.startsWith('cat_')) {
      try {
        final catRes = await _dio.get('/expense-categories');
        final catList = catRes.data['data'] as List<dynamic>;
        if (catList.isNotEmpty) {
          realCategoryId = catList.first['id'];
        } else {
          final createRes = await _dio.post('/expense-categories', data: {
            'name': 'General Expense',
            'iconKey': 'receipt',
          });
          realCategoryId = createRes.data['data']['id'];
        }
      } catch (_) {}
    }

    final formattedAmount = amount.toStringAsFixed(2);
    final dateIso = spentAt.toIso8601String();
    final data = {
      'accountId': accountId,
      'categoryId': realCategoryId,
      'amount': formattedAmount,
      'description': description,
      'spentAt': dateIso,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    // Queue offline before API call
    final txnId = await cacheService.queueTransaction('expense', data);

    try {
      await _dio.post('/expenses', data: data);
      // Mark as synced on success
      await cacheService.markSynced(txnId);
    } catch (_) {
      // API failed — transaction remains queued for later sync
    }

    _ref.invalidate(dashboardProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> addIncome({
    required String accountId,
    required double amount,
    required String source,
    required DateTime receivedAt,
    String? notes,
  }) async {
    final cacheService = _ref.read(cacheServiceProvider);

    final formattedAmount = amount.toStringAsFixed(2);
    final dateIso = receivedAt.toIso8601String();
    final data = {
      'accountId': accountId,
      'amount': formattedAmount,
      'source': source,
      'receivedAt': dateIso,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    // Queue offline before API call
    final txnId = await cacheService.queueTransaction('income', data);

    try {
      await _dio.post('/income', data: data);
      // Mark as synced on success
      await cacheService.markSynced(txnId);
    } catch (_) {
      // API failed — transaction remains queued for later sync
    }

    _ref.invalidate(dashboardProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final cacheService = _ref.read(cacheServiceProvider);

    final data = {
      'name': name,
      'targetAmount': targetAmount.toStringAsFixed(2),
      if (targetDate != null) 'targetDate': targetDate.toIso8601String(),
    };

    // Queue offline before API call
    final txnId = await cacheService.queueTransaction('goal', data);

    try {
      await _dio.post('/goals', data: data);
      // Mark as synced on success
      await cacheService.markSynced(txnId);
    } catch (_) {
      // API failed — transaction remains queued for later sync
    }

    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
  }

  Future<void> addGoalContribution({
    required String goalId,
    required double amount,
    String? notes,
  }) async {
    final cacheService = _ref.read(cacheServiceProvider);

    final data = {
      'amount': amount,
      'contributedAt': DateTime.now().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    // Queue offline before API call
    final txnId = await cacheService.queueTransaction('goal_contribution', data);

    try {
      await _dio.post('/goals/$goalId/contributions', data: data);
      await cacheService.markSynced(txnId);
    } catch (_) {}

    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
  }

  Future<void> addBill({
    required String name,
    required double amount,
    required DateTime startsOn,
    String recurrence = 'monthly',
  }) async {
    final cacheService = _ref.read(cacheServiceProvider);

    final data = {
      'name': name,
      'defaultAmount': amount.toStringAsFixed(2),
      'startsOn': startsOn.toIso8601String(),
      'recurrence': recurrence,
    };

    // Queue offline before API call
    final txnId = await cacheService.queueTransaction('bill', data);

    try {
      await _dio.post('/bill-templates', data: data);
      // Mark as synced on success
      await cacheService.markSynced(txnId);
    } catch (_) {
      // API failed — transaction remains queued for later sync
    }

    _ref.invalidate(billsProvider);
    _ref.invalidate(dashboardProvider);
  }
}

final transactionMutatorProvider = Provider<TransactionMutator>((ref) {
  final dio = ref.watch(dioProvider);
  return TransactionMutator(dio, ref);
});

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
    bool? readAt,
  }) = _AlertItem;

  factory AlertItem.fromJson(Map<String, dynamic> json) => _$AlertItemFromJson(json);
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
    return [];
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
      budgets: (json['budgets'] as List<dynamic>?)
              ?.map((e) => BudgetItemStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

final budgetStatusProvider = FutureProvider<BudgetStatus>((ref) async {
  final dio = ref.watch(dioProvider);
  final now = DateTime.now();
  final monthStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';
  try {
    final res =
        await dio.get('/budgets/status', queryParameters: {'month': monthStr});
    return BudgetStatus.fromJson(
        res.data['data'] as Map<String, dynamic>);
  } catch (_) {
    return BudgetStatus.empty();
  }
});
