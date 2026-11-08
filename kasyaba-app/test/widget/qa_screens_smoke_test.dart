// Layout smoke coverage for every routed screen.
//
// Each screen is mounted with deterministic provider overrides and must finish
// its initial build with no Flutter exception (overflow, failed assertion,
// null dereference in build). Deep interactions are intentionally out of scope.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/accounts/screens/accounts_screen.dart';
import 'package:kasyaba/features/alerts/screens/alerts_screen.dart';
import 'package:kasyaba/features/auth/screens/forgot_password_screen.dart';
import 'package:kasyaba/features/auth/screens/login_screen.dart';
import 'package:kasyaba/features/auth/screens/register_screen.dart';
import 'package:kasyaba/features/bills/screens/add_bill_screen.dart';
import 'package:kasyaba/features/bills/screens/bills_screen.dart';
import 'package:kasyaba/features/budgets/screens/budgets_screen.dart';
import 'package:kasyaba/features/dashboard/screens/dashboard_screen.dart';
import 'package:kasyaba/features/planning/screens/math_breakdown_screen.dart';
import 'package:kasyaba/features/planning/screens/planning_screen.dart';
import 'package:kasyaba/features/savings/screens/create_goal_screen.dart';
import 'package:kasyaba/features/savings/screens/goal_detail_screen.dart';
import 'package:kasyaba/features/savings/screens/goals_screen.dart';
import 'package:kasyaba/features/settings/screens/backup_export_screen.dart';
import 'package:kasyaba/features/settings/screens/delete_account_screen.dart';
import 'package:kasyaba/features/settings/screens/notification_settings_screen.dart';
import 'package:kasyaba/features/settings/screens/privacy_about_screen.dart';
import 'package:kasyaba/features/settings/screens/settings_screen.dart';
import 'package:kasyaba/features/splash/screens/splash_screen.dart';
import 'package:kasyaba/features/transactions/screens/add_transaction_screen.dart';
import 'package:kasyaba/features/transactions/screens/transactions_screen.dart';

import 'support/qa_harness.dart';

const SavingsGoal _qaSmokeGoal = SavingsGoal(
  id: 'goal-smoke-1',
  name: 'QA Smoke Goal',
  targetAmount: 30000,
  currentAmount: 5000,
  targetDate: '2027-06-01',
  canAffordByTargetDate: true,
);

void main() {
  void registerSmokeTest(
    String name,
    Widget Function() build, {
    List<Override> Function()? overrides,
    bool settle = true,
  }) {
    testWidgets('$name mounts without layout exceptions', (tester) async {
      final harness = QaHarness();
      await harness.pumpScreen(
        tester,
        build(),
        overrides: overrides?.call() ?? qaDefaultDataOverrides(),
        settle: settle,
      );

      if (!settle) {
        // Splash/Login/Register own indeterminate animations, so
        // pumpAndSettle can never complete; a fixed pump is enough to prove
        // the first frame laid out cleanly.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        if (name == 'SplashScreen') {
          expect(find.text('KASYABA'), findsOneWidget);
        }
      }
    });
  }

  registerSmokeTest(
    'SplashScreen',
    () => const SplashScreen(),
    overrides: () => const <Override>[],
    settle: false,
  );
  registerSmokeTest(
    'LoginScreen',
    () => const LoginScreen(),
    settle: false,
  );
  registerSmokeTest(
    'RegisterScreen',
    () => const RegisterScreen(),
    settle: false,
  );
  registerSmokeTest(
    'ForgotPasswordScreen',
    () => const ForgotPasswordScreen(),
  );
  registerSmokeTest('DashboardScreen', () => const DashboardScreen());
  registerSmokeTest('PlanningScreen', () => const PlanningScreen());
  registerSmokeTest(
    'TransactionsScreen',
    () => const TransactionsScreen(),
  );
  registerSmokeTest('BillsScreen', () => const BillsScreen());
  registerSmokeTest('GoalsScreen', () => const GoalsScreen());
  registerSmokeTest('BudgetsScreen', () => const BudgetsScreen());
  registerSmokeTest('AlertsScreen', () => const AlertsScreen());
  registerSmokeTest('SettingsScreen', () => const SettingsScreen());
  registerSmokeTest('AccountsScreen', () => const AccountsScreen());
  registerSmokeTest(
    'NotificationSettingsScreen',
    () => const NotificationSettingsScreen(),
  );
  registerSmokeTest(
    'BackupExportScreen',
    () => const BackupExportScreen(),
    overrides: () => const <Override>[],
  );
  registerSmokeTest(
    'DeleteAccountScreen',
    () => const DeleteAccountScreen(),
    overrides: () => const <Override>[],
  );
  registerSmokeTest(
    'PrivacyAndAboutScreen',
    () => const PrivacyAndAboutScreen(),
    overrides: () => const <Override>[],
  );
  registerSmokeTest(
    'MathBreakdownScreen',
    () => const MathBreakdownScreen(),
  );
  registerSmokeTest(
    'AddTransactionScreen',
    () => const AddTransactionScreen(),
  );
  registerSmokeTest('AddBillScreen', () => const AddBillScreen());
  registerSmokeTest('CreateGoalScreen', () => const CreateGoalScreen());
  registerSmokeTest(
    'GoalDetailScreen',
    () => const GoalDetailScreen(
      goalId: 'goal-smoke-1',
      initialGoal: _qaSmokeGoal,
    ),
    overrides: () => qaDefaultDataOverrides(
      goals: <SavingsGoal>[_qaSmokeGoal],
    ),
  );
}
