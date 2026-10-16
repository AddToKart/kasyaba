import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/utils/data_export_helper.dart';

void main() {
  group('DataExportHelper - CSV Generation', () {
    test('generates valid RFC 4180 CSV with escaped fields and signed amounts', () {
      final transactions = [
        TransactionEntry(
          id: 'tx-1',
          title: 'Grocery, Market & Snacks',
          amount: 1540.50,
          isExpense: true,
          date: DateTime(2026, 10, 15),
          categoryName: 'Food & Dining',
          type: 'expense',
          accountId: 'acc-1',
          notes: 'Weekly groceries "SM"',
        ),
        TransactionEntry(
          id: 'tx-2',
          title: 'Consulting Pay',
          amount: 25000.00,
          isExpense: false,
          date: DateTime(2026, 10, 16),
          categoryName: 'Salary',
          type: 'income',
          accountId: 'acc-2',
          notes: 'Milestone 2',
        ),
        TransactionEntry(
          id: 'tx-3',
          title: 'Transfer to GCash',
          amount: 3000.00,
          isExpense: false,
          date: DateTime(2026, 10, 16),
          categoryName: 'Transfer',
          type: 'transfer',
          accountId: 'acc-1',
        ),
      ];

      final accountNames = {
        'acc-1': 'BDO Checking',
        'acc-2': 'Maya Wallet',
      };

      final csv = DataExportHelper.generateTransactionsCsv(
        transactions: transactions,
        accountNames: accountNames,
      );

      final lines = csv.trim().split('\n');
      expect(lines.length, 4); // Header + 3 entries
      expect(lines[0], 'Date,Type,Description,Category,Amount (PHP),Account / Wallet,Notes,Status');
      // Entry 1
      expect(lines[1], contains('2026-10-15,EXPENSE,"Grocery, Market & Snacks",Food & Dining,-1540.50,BDO Checking,"Weekly groceries ""SM""",POSTED'));
      // Entry 2
      expect(lines[2], contains('2026-10-16,INCOME,Consulting Pay,Salary,+25000.00,Maya Wallet,Milestone 2,POSTED'));
      // Entry 3
      expect(lines[3], contains('2026-10-16,TRANSFER,Transfer to GCash,Transfer,3000.00,BDO Checking,,POSTED'));
    });
  });

  group('DataExportHelper - JSON Schema Validation', () {
    test('rejects invalid JSON syntax', () {
      final result = DataExportHelper.validateBackup('this is not { valid json }');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid JSON'));
    });

    test('rejects empty / irrelevant JSON payload', () {
      final result = DataExportHelper.validateBackup('{"foo": "bar", "num": 123}');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unrecognized backup schema'));
    });

    test('validates full Kasyaba envelope backup successfully', () {
      final backup = {
        'exportedAt': '2026-10-16T12:00:00.000Z',
        'user': {
          'id': 'u1',
          'email': 'kurt@example.com',
          'displayName': 'Kurt',
          'financialAccounts': [
            {'id': 'a1', 'name': 'BDO Checking'},
            {'id': 'a2', 'name': 'GCash'},
          ],
          'expenseEntries': [
            {'id': 'e1', 'amount': 250.0},
            {'id': 'e2', 'amount': 120.0},
            {'id': 'e3', 'amount': 99.0},
          ],
          'incomeEntries': [
            {'id': 'i1', 'amount': 45000.0},
          ],
          'transfers': [
            {'id': 't1', 'amount': 1000.0},
          ],
          'savingsGoals': [
            {'id': 'g1', 'name': 'Emergency Fund'},
          ],
          'budgets': [
            {'id': 'b1', 'amount': 10000.0},
          ],
          'billTemplates': [
            {'id': 'bt1', 'name': 'Meralco'},
          ],
        },
      };

      final result = DataExportHelper.validateBackup(jsonEncode(backup));
      expect(result.isValid, isTrue);
      expect(result.userEmail, 'kurt@example.com');
      expect(result.accountCount, 2);
      expect(result.expenseCount, 3);
      expect(result.incomeCount, 1);
      expect(result.transferCount, 1);
      expect(result.goalCount, 1);
      expect(result.budgetCount, 1);
      expect(result.billCount, 1);
      expect(result.totalRecordsCount, 10);
    });
  });
}
