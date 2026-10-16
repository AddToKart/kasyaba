import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/accounts/widgets/reconcile_balance_sheet.dart';
import 'package:kasyaba/features/transactions/screens/add_transaction_screen.dart';

void main() {
  const testAccounts = [
    Account(
      id: 'acc-1111-1111-1111-1111-111111111111',
      name: 'BDO Checking',
      type: 'bank',
    ),
    Account(
      id: 'acc-2222-2222-2222-2222-222222222222',
      name: 'GCash Wallet',
      type: 'ewallet',
    ),
  ];

  final testBalances = {
    'acc-1111-1111-1111-1111-111111111111': 9172.0,
    'acc-2222-2222-2222-2222-222222222222': 3450.0,
  };

  group('AddTransactionScreen - 3-Way Mode & Transfer Mode', () {
    testWidgets('switches to Transfer mode and displays dual wallet selectors & fee presets', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) async => testAccounts),
            accountBalancesProvider.overrideWith((ref) async => testBalances),
            categoriesProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: AddTransactionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the 3-way toggle has Expense, Income, and Transfer
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);

      // By default it starts as Expense
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('From Account / Wallet'), findsNothing);

      // Tap on "Transfer" mode
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      // Category should be hidden; From and To wallet selectors should be visible
      expect(find.text('Category'), findsNothing);
      expect(find.text('From Account / Wallet'), findsOneWidget);
      expect(find.text('To Account / Wallet'), findsOneWidget);

      // Transfer Fee input and quick-select presets should be visible
      expect(find.text('Transfer Fee (Optional)'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('₱10'), findsOneWidget);
      expect(find.text('₱15 InstaPay'), findsOneWidget);
      expect(find.text('₱25'), findsOneWidget);

      // Tapping a fee preset pill updates the fee input
      await tester.tap(find.text('₱15 InstaPay'));
      await tester.pumpAndSettle();

      // Find the TextField with 15.00
      expect(find.text('15.00'), findsOneWidget);

      // Save button now says "Save Transfer"
      expect(find.text('Save Transfer'), findsOneWidget);
    });
  });

  group('ReconcileBalanceSheet - 1-Tap Wallet Balance Reconciliation', () {
    testWidgets('renders recorded balance and calculates live discrepancies accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final account = testAccounts.first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) async => testAccounts),
            accountBalancesProvider.overrideWith((ref) async => testBalances),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReconcileBalanceSheet(initialAccount: account),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header checks
      expect(find.text('Reconcile Balance'), findsOneWidget);
      expect(find.text('BDO Checking'), findsWidgets);

      // Recorded app balance: ₱9,172.00
      expect(find.text('RECORDED APP BALANCE'), findsOneWidget);
      expect(find.text('₱9,172.00'), findsWidgets);

      // Real-World Balance prompt
      expect(find.text('ACTUAL REAL-WORLD BALANCE'), findsOneWidget);

      // Initially prompt says "Enter your actual physical cash or bank balance to calculate discrepancy."
      expect(
        find.text(
          'Enter your actual physical cash or bank balance to calculate discrepancy.',
        ),
        findsOneWidget,
      );

      // Find input field for actual balance and enter 8850 (deficit / negative discrepancy of -₱322.00)
      final inputField = find.byType(TextField).first;
      await tester.enterText(inputField, '8850.00');
      await tester.pumpAndSettle();

      // Should show -₱322.00 discrepancy
      expect(find.text('Discrepancy: -₱322.00'), findsOneWidget);
      expect(find.text('Sync & Log Adjustment'), findsOneWidget);

      // Enter matching balance 9172.00 (perfect sync)
      await tester.enterText(inputField, '9172.00');
      await tester.pumpAndSettle();

      expect(find.text('In Perfect Sync (₱0.00 discrepancy)'), findsOneWidget);
      expect(find.text('Balances Already Match'), findsOneWidget);

      // Enter surplus balance 10000.00 (+₱828.00 surplus)
      await tester.enterText(inputField, '10000.00');
      await tester.pumpAndSettle();

      expect(find.text('Discrepancy: +₱828.00'), findsOneWidget);
      expect(find.text('Sync & Log Adjustment'), findsOneWidget);
    });
  });
}
