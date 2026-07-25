import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

// -----------------------------------------------------------------------------
// Financial Account Model & Provider
// -----------------------------------------------------------------------------
class Account {
  final String id;
  final String name;
  final String type;

  Account({required this.id, required this.name, required this.type});

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        type: (json['type'] as String?) ?? 'cash',
      );
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
class Category {
  final String id;
  final String name;
  final String iconKey;

  Category({required this.id, required this.name, required this.iconKey});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: (json['iconKey'] as String?) ?? 'receipt',
      );
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
class CategoryExpenseSummary {
  final String categoryName;
  final String iconKey;
  final double total;

  CategoryExpenseSummary({required this.categoryName, required this.iconKey, required this.total});

  factory CategoryExpenseSummary.fromJson(Map<String, dynamic> json) {
    return CategoryExpenseSummary(
      categoryName: json['categoryName']?.toString() ?? 'Other',
      iconKey: json['iconKey']?.toString() ?? 'receipt',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DashboardData {
  final double totalBalance;
  final double income;
  final double expenses;
  final double savings;
  final String healthScore;
  final double predictedMonthEnd;
  final List<CategoryExpenseSummary> categoryExpenses;

  DashboardData({
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.healthScore,
    required this.predictedMonthEnd,
    required this.categoryExpenses,
  });

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

    String grade = 'Good';
    if (json['healthGrade'] != null) {
      grade = json['healthGrade'].toString();
    } else if (json['healthScore'] != null) {
      final score = parseNum(json['healthScore']);
      if (score >= 80) {
        grade = 'Excellent';
      } else if (score >= 60) {
        grade = 'Good';
      } else if (score >= 40) {
        grade = 'Fair';
      } else {
        grade = 'Poor';
      }
    }

    return DashboardData(
      totalBalance: parseNum(json['balance'] ?? json['actualBalance'] ?? json['currentBalance']),
      income: parseNum(json['income'] ?? json['incomeMonthToDate'] ?? json['monthToDateIncome']),
      expenses: parseNum(json['expenses'] ?? json['expensesMonthToDate'] ?? json['monthToDateExpenses']),
      savings: parseNum(json['savings'] ?? json['savingsMonthToDate']),
      healthScore: grade,
      predictedMonthEnd: parseNum(json['predictedMonthEndBalance'] ?? json['predictedBalance']),
      categoryExpenses: cats,
    );
  }
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/dashboard');
    return DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
  } catch (e) {
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
class TransactionEntry {
  final String id;
  final String title;
  final double amount;
  final bool isExpense;
  final DateTime date;
  final String categoryName;

  TransactionEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.date,
    required this.categoryName,
  });
}

final transactionsProvider = FutureProvider<List<TransactionEntry>>((ref) async {
  final dio = ref.watch(dioProvider);
  final List<TransactionEntry> items = [];

  try {
    // Fetch Expenses
    final expRes = await dio.get('/expenses');
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
    final incRes = await dio.get('/income');
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

  return items;
});

// -----------------------------------------------------------------------------
// Savings Goals Model & Provider
// -----------------------------------------------------------------------------
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? targetDate;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: parseNum(json['targetAmount']),
      currentAmount: parseNum(json['currentAmount'] ?? json['savedAmount']),
      targetDate: json['targetDate']?.toString(),
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
class BillItem {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final String status;

  BillItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
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

    await _dio.post('/expenses', data: {
      'accountId': accountId,
      'categoryId': realCategoryId,
      'amount': formattedAmount,
      'description': description,
      'spentAt': dateIso,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

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
    final formattedAmount = amount.toStringAsFixed(2);
    final dateIso = receivedAt.toIso8601String();

    await _dio.post('/income', data: {
      'accountId': accountId,
      'amount': formattedAmount,
      'source': source,
      'receivedAt': dateIso,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

    _ref.invalidate(dashboardProvider);
    _ref.invalidate(transactionsProvider);
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    await _dio.post('/goals', data: {
      'name': name,
      'targetAmount': targetAmount.toStringAsFixed(2),
      if (targetDate != null) 'targetDate': targetDate.toIso8601String(),
    });
    _ref.invalidate(goalsProvider);
    _ref.invalidate(dashboardProvider);
  }

  Future<void> addBill({
    required String name,
    required double amount,
    required DateTime startsOn,
    String recurrence = 'monthly',
  }) async {
    await _dio.post('/bill-templates', data: {
      'name': name,
      'defaultAmount': amount.toStringAsFixed(2),
      'startsOn': startsOn.toIso8601String(),
      'recurrence': recurrence,
    });
    _ref.invalidate(billsProvider);
    _ref.invalidate(dashboardProvider);
  }
}

final transactionMutatorProvider = Provider<TransactionMutator>((ref) {
  final dio = ref.watch(dioProvider);
  return TransactionMutator(dio, ref);
});
