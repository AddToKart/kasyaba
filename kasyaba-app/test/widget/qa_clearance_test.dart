// Dock-clearance token regression.
//
// Every docked screen must end its primary scrollable exactly at
// `KasyabaTokens.dockClearance` (120) so content never hides under the floating
// dock. The two migrated sheets must also keep their CTA above the token with
// the keyboard closed on an 812px-tall viewport.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/app/theme/kasyaba_tokens.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/alerts/screens/alerts_screen.dart';
import 'package:kasyaba/features/bills/screens/bills_screen.dart';
import 'package:kasyaba/features/budgets/screens/budgets_screen.dart';
import 'package:kasyaba/features/dashboard/screens/dashboard_screen.dart';
import 'package:kasyaba/features/dashboard/widgets/kasyaba_affordability_sheet.dart';
import 'package:kasyaba/features/planning/screens/planning_screen.dart';
import 'package:kasyaba/features/savings/screens/goals_screen.dart';
import 'package:kasyaba/features/savings/widgets/goal_deposit_sheet.dart';
import 'package:kasyaba/features/settings/screens/settings_screen.dart';
import 'package:kasyaba/features/transactions/screens/transactions_screen.dart';
import 'package:kasyaba/shared/widgets/app_sheet.dart';

import 'support/qa_harness.dart';

const Size _qaDockViewport = Size(800, 812);

void main() {
  void registerScreenClearanceTest(
    String name,
    Widget Function() build,
  ) {
    testWidgets('$name keeps the dock clearance at the bottom', (tester) async {
      final harness = QaHarness();
      await harness.pumpScreen(
        tester,
        build(),
        overrides: qaDefaultDataOverrides(),
        viewport: _qaDockViewport,
      );

      qaExpectDockClearance(tester);
    });
  }

  registerScreenClearanceTest('PlanningScreen', () => const PlanningScreen());
  registerScreenClearanceTest(
    'TransactionsScreen',
    () => const TransactionsScreen(),
  );
  registerScreenClearanceTest('BillsScreen', () => const BillsScreen());
  registerScreenClearanceTest(
    'DashboardScreen',
    () => const DashboardScreen(),
  );
  registerScreenClearanceTest('GoalsScreen', () => const GoalsScreen());
  registerScreenClearanceTest('BudgetsScreen', () => const BudgetsScreen());
  registerScreenClearanceTest('AlertsScreen', () => const AlertsScreen());
  registerScreenClearanceTest('SettingsScreen', () => const SettingsScreen());

  testWidgets(
    'goal deposit CTA keeps the dock clearance with the keyboard closed',
    (tester) async {
      const goal = SavingsGoal(
        id: 'goal-qa-1',
        name: 'QA Emergency Fund',
        targetAmount: 50000,
        currentAmount: 10000,
      );

      final harness = QaHarness();
      await harness.pumpScreen(
        tester,
        QaSheetLauncher(
          label: 'Open deposit',
          onLaunch: (context) => showGoalDepositSheet(context, goal),
        ),
        overrides: <Override>[
          accountsProvider.overrideWith(
            (ref) async => const <Account>[qaDefaultAccount],
          ),
          accountBalancesProvider.overrideWith(
            (ref) async => const <String, double>{qaAccountId: 5000},
          ),
        ],
        viewport: _qaDockViewport,
      );

      await tester.tap(find.text('Open deposit'));
      await qaSettle(tester);

      _expectSheetBottomClearance(tester);
    },
  );

  testWidgets(
    'affordability CTA keeps the dock clearance with the keyboard closed',
    (tester) async {
      final harness = QaHarness();
      await harness.pumpScreen(
        tester,
        QaSheetLauncher(
          label: 'Open affordability',
          onLaunch: (context) => showKasyaBaAffordabilitySheet(context),
        ),
        overrides: qaDefaultDataOverrides(),
        viewport: _qaDockViewport,
      );

      await tester.tap(find.text('Open affordability'));
      await qaSettle(tester);

      _expectSheetBottomClearance(tester);
    },
  );
}

void _expectSheetBottomClearance(WidgetTester tester) {
  final scrollFinder = find.descendant(
    of: find.byType(AppSheet),
    matching: find.byType(SingleChildScrollView),
  );
  expect(
    scrollFinder,
    findsOneWidget,
    reason: 'Sheet must render its scrollable content inside AppSheet.',
  );

  final scrollView = tester.widget<SingleChildScrollView>(scrollFinder);
  final padding = scrollView.padding;
  expect(
    padding,
    isA<EdgeInsets>(),
    reason: 'Sheet padding must be concrete EdgeInsets to inspect clearance.',
  );
  expect(
    (padding! as EdgeInsets).bottom,
    greaterThanOrEqualTo(KasyabaTokens.dockClearance),
    reason: 'Sheet CTA must keep at least the dock clearance at the bottom.',
  );
}
