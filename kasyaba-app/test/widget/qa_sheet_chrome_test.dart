// Sheet-unification regression coverage.
//
// Every migrated bottom sheet must render exactly one shared `AppSheet` chrome
// (r32 top corners + the 44x5 token handle) and no legacy hand-drawn handle.
//
// NOTE: four surfaces currently fail this contract (they switched from
// `showModalBottomSheet` to `showKasyabaSheet` without wrapping their content
// in `AppSheet`). Those failures are intentional regression findings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/accounts/screens/accounts_screen.dart';
import 'package:kasyaba/features/bills/screens/add_bill_screen.dart';
import 'package:kasyaba/features/bills/screens/bills_screen.dart';
import 'package:kasyaba/features/budgets/screens/budgets_screen.dart';
import 'package:kasyaba/features/dashboard/widgets/kasyaba_affordability_sheet.dart';
import 'package:kasyaba/features/savings/widgets/goal_deposit_sheet.dart';
import 'package:kasyaba/features/settings/screens/backup_export_screen.dart';
import 'package:kasyaba/features/settings/screens/privacy_about_screen.dart';
import 'package:kasyaba/features/settings/screens/settings_screen.dart';
import 'package:kasyaba/features/transactions/screens/add_transaction_screen.dart';
import 'package:kasyaba/features/transactions/screens/transactions_screen.dart';

import 'support/qa_harness.dart';

void main() {
  const qaGoal = SavingsGoal(
    id: 'goal-qa-1',
    name: 'QA Emergency Fund',
    targetAmount: 50000,
    currentAmount: 10000,
  );

  testWidgets('transactions action sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final transaction = TransactionEntry(
      id: 'tx-qa-1',
      title: 'QA Coffee',
      amount: 150,
      isExpense: true,
      date: DateTime.now(),
      categoryName: 'Food & Dining',
      type: 'expense',
      status: 'posted',
      accountId: qaAccountId,
    );

    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const TransactionsScreen(),
      overrides: <Override>[
        billsProvider.overrideWith((ref) async => const <BillItem>[]),
        paginatedTransactionsProvider.overrideWith(
          (ref) async => PaginatedTransactions(
            items: <TransactionEntry>[transaction],
            page: 1,
            limit: 50,
            totalCount: 1,
          ),
        ),
      ],
    );

    await qaTapVisible(tester, find.text('QA Coffee'));
    await qaSettle(tester);

    // The sheet did open; only its chrome is missing.
    expect(find.text('Delete transaction'), findsOneWidget);
    qaExpectAppSheetChrome(tester);
  });

  testWidgets('bills mark-paid sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final bill = BillItem(
      id: 'bill-qa-1',
      name: 'QA Internet',
      amount: 1500,
      dueDate: DateTime.now(),
      status: 'unpaid',
    );

    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const BillsScreen(),
      overrides: <Override>[
        billsProvider.overrideWith((ref) async => <BillItem>[bill]),
        accountsProvider.overrideWith(
          (ref) async => const <Account>[qaDefaultAccount],
        ),
        accountBalancesProvider.overrideWith(
          (ref) async => const <String, double>{qaAccountId: 5000},
        ),
      ],
    );

    await qaTapVisible(tester, find.text('QA Internet'));
    await qaSettle(tester);

    // The sheet did open; only its chrome is missing.
    expect(find.text('Mark as Paid'), findsOneWidget);
    qaExpectAppSheetChrome(tester);
  });

  testWidgets('budgets create sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const BudgetsScreen(),
      overrides: qaDefaultDataOverrides(),
    );

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await qaSettle(tester);

    qaExpectAppSheetChrome(tester);
  });

  testWidgets('add-transaction account picker uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const AddTransactionScreen(),
      overrides: <Override>[
        accountsProvider.overrideWith(
          (ref) async => const <Account>[qaDefaultAccount],
        ),
        accountBalancesProvider.overrideWith(
          (ref) async => const <String, double>{qaAccountId: 5000},
        ),
        categoriesProvider.overrideWith(
          (ref) async => defaultCategoriesList,
        ),
      ],
    );

    await qaTapVisible(tester, find.text('Cash Wallet'));
    await qaSettle(tester);

    // The sheet did open; only its chrome is missing.
    expect(find.text('Select Account'), findsOneWidget);
    qaExpectAppSheetChrome(tester);
  });

  testWidgets('add-bill category picker uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const AddBillScreen(),
      overrides: <Override>[
        categoriesProvider.overrideWith(
          (ref) async => defaultCategoriesList,
        ),
      ],
    );

    await qaTapVisible(tester, find.text('Select category'));
    await qaSettle(tester);

    // The sheet did open; only its chrome is missing.
    expect(find.text('Select Category'), findsOneWidget);
    qaExpectAppSheetChrome(tester);
  });

  testWidgets('goal deposit sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      QaSheetLauncher(
        label: 'Open deposit',
        onLaunch: (context) => showGoalDepositSheet(context, qaGoal),
      ),
      overrides: <Override>[
        accountsProvider.overrideWith(
          (ref) async => const <Account>[qaDefaultAccount],
        ),
        accountBalancesProvider.overrideWith(
          (ref) async => const <String, double>{qaAccountId: 5000},
        ),
      ],
    );

    await tester.tap(find.text('Open deposit'));
    await qaSettle(tester);

    qaExpectAppSheetChrome(tester);
  });

  testWidgets('affordability sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      QaSheetLauncher(
        label: 'Open affordability',
        onLaunch: (context) => showKasyaBaAffordabilitySheet(context),
      ),
      overrides: qaDefaultDataOverrides(),
    );

    await tester.tap(find.text('Open affordability'));
    await qaSettle(tester);

    qaExpectAppSheetChrome(tester);
  });

  testWidgets('reconcile sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const AccountsScreen(),
      overrides: qaDefaultDataOverrides(),
      // Flutter's test font renders every glyph ~1em wide, which makes the
      // fixed-width (280px) Material popup menu overflow. Slightly reduce the
      // text scale so this test exercises the real sheet chrome rather than an
      // Ahem-only menu artifact.
      textScaler: const TextScaler.linear(0.8),
    );

    await qaTapVisible(tester, find.byIcon(Icons.more_vert_rounded).first);
    await tester.tap(find.text('Reconcile balance'));
    await qaSettle(tester);

    qaExpectAppSheetChrome(tester);
  });

  testWidgets('settings salary sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const SettingsScreen(),
      overrides: <Override>[
        userProfileProvider.overrideWith((ref) async => qaDefaultProfile()),
        budgetStatusProvider.overrideWith(
          (ref) async => BudgetStatus.empty(),
        ),
      ],
    );

    await tester.tap(find.text('Set salary'));
    await qaSettle(tester);

    qaExpectAppSheetChrome(tester);
  });

  testWidgets('backup export sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(tester, const BackupExportScreen());

    await tester.tap(find.text('Create backup'));
    await qaSettle(tester);

    qaExpectAppSheetChrome(tester);
  });

  testWidgets('backup restore sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(tester, const BackupExportScreen());

    await tester.tap(find.text('Choose file'));
    await qaSettle(tester);

    qaExpectAppSheetChrome(tester);
  });

  testWidgets('CSV export sheet uses the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const BackupExportScreen(),
      overrides: qaDefaultDataOverrides(),
    );

    await tester.tap(find.text('Export transactions'));
    await qaSettle(tester);

    qaExpectAppSheetChrome(tester);
  });

  testWidgets('privacy and about sheets use the shared AppSheet chrome', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(tester, const PrivacyAndAboutScreen());

    await tester.tap(find.text('Terms of service'));
    await qaSettle(tester);
    qaExpectAppSheetChrome(tester);

    await tester.tap(find.text('Close'));
    await qaSettle(tester);

    await tester.tap(find.text('Privacy policy'));
    await qaSettle(tester);
    qaExpectAppSheetChrome(tester);
  });

  testWidgets(
    'budget create sheet keeps its CTA reachable with a 320px keyboard inset',
    (tester) async {
      final harness = QaHarness();
      await harness.pumpScreen(
        tester,
        const BudgetsScreen(),
        overrides: qaDefaultDataOverrides(),
        viewport: const Size(800, 812),
      );

      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await qaSettle(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Opening the keyboard over the budget sheet must not overflow.',
      );
      expect(find.text('Create Budget'), findsOneWidget);

      await tester.ensureVisible(find.text('Create Budget'));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'The save CTA must remain reachable with the keyboard open.',
      );
    },
  );
}
