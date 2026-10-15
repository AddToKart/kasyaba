import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/database/database.dart';
import 'package:kasyaba/core/providers/api_providers.dart';

void main() {
  group('DashboardData.fromJson', () {
    test('parses balances, budget usage, and charts', () {
      final data = DashboardData.fromJson({
        'balance': '12500.00',
        'income': '25000.00',
        'expenses': '9800.00',
        'savings': '2500.00',
        'healthGrade': 'Good',
        'predictedMonthEndBalance': '4800.00',
        'budgetUsedPercent': 65.3,
        'charts': {
          'expensesByCategory': [
            {'categoryName': 'Food', 'iconKey': 'restaurant', 'total': '120.50'},
          ],
          'dailyBalance': [
            {'date': '2026-10-01', 'balance': '100.00', 'predictedEnd': '90.00'},
          ],
        },
      });

      expect(data.totalBalance, 12500.00);
      expect(data.income, 25000.00);
      expect(data.budgetUsedPercent, 65.3);
      expect(data.categoryExpenses.single.total, 120.50);
      expect(data.dailyBalance.single.projected, 90.00);
    });

    test('defaults budget usage to zero when absent', () {
      final data = DashboardData.fromJson({
        'balance': '0',
        'income': '0',
        'expenses': '0',
        'savings': '0',
        'healthGrade': 'Needs Attention',
        'predictedMonthEndBalance': '0',
      });
      expect(data.budgetUsedPercent, 0.0);
      expect(data.categoryExpenses, isEmpty);
    });
  });

  group('AlertItem.fromJson', () {
    Map<String, dynamic> alertJson({String? readAt}) => {
      'id': 'alert-1',
      'type': 'low_balance',
      'severity': 'warning',
      'title': 'Low balance warning',
      'message': 'Your projected balance is low.',
      'createdAt': '2026-10-01T00:00:00.000Z',
      'readAt': readAt,
    };

    test('parses an ISO read timestamp without crashing', () {
      final alert = AlertItem.fromJson(
        alertJson(readAt: '2026-10-02T00:00:00.000Z'),
      );
      expect(alert.isRead, isTrue);
      expect(alert.readAt, isA<DateTime>());
    });

    test('treats a missing readAt as unread', () {
      final alert = AlertItem.fromJson(alertJson());
      expect(alert.isRead, isFalse);
      expect(alert.readAt, isNull);
    });
  });

  group('offlineTransactionToEntry & isPendingSync (F9)', () {
    test('maps queued offline expense correctly', () {
      final ot = OfflineTransaction(
        id: 'offline-exp-1',
        userId: 'user-1',
        type: 'expense',
        json: '{"amount": "450.00", "merchant": "Jollibee", "spentAt": "2026-10-15T12:00:00.000Z"}',
        createdAt: DateTime(2026, 10, 15, 12, 0),
        retryCount: 0,
      );

      final entry = offlineTransactionToEntry(ot);
      expect(entry.id, 'offline-exp-1');
      expect(entry.title, 'Jollibee');
      expect(entry.amount, 450.00);
      expect(entry.isExpense, isTrue);
      expect(entry.status, 'pending_sync');
      expect(entry.isPendingSync, isTrue);
    });

    test('maps queued offline income correctly', () {
      final ot = OfflineTransaction(
        id: 'offline-inc-1',
        userId: 'user-1',
        type: 'income',
        json: '{"amount": "30000.00", "source": "Salary Inflow", "receivedAt": "2026-10-15T10:00:00.000Z"}',
        createdAt: DateTime(2026, 10, 15, 10, 0),
        retryCount: 0,
      );

      final entry = offlineTransactionToEntry(ot);
      expect(entry.id, 'offline-inc-1');
      expect(entry.title, 'Salary Inflow');
      expect(entry.amount, 30000.00);
      expect(entry.isExpense, isFalse);
      expect(entry.status, 'pending_sync');
      expect(entry.isPendingSync, isTrue);
    });
  });
}

