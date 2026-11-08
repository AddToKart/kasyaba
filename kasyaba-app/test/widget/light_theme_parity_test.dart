// Light-mode parity smoke for every routed screen (Phase LT-E).
//
// Each screen is mounted twice — once in [ThemeMode.dark] and once in
// [ThemeMode.light] — with the same deterministic provider overrides used by
// `qa_screens_smoke_test.dart`. A run must:
//   1. build without a Flutter exception (overflow / failed assertion),
//   2. resolve [Theme.of] to the expected brightness, and
//   3. paint the scaffold / first rendered Material with the palette canvas
//      (`#0A1220` dark, `#F6F8FB` light).
//
// This is intentionally screenshot-like, not pixel-perfect: it catches the
// class of regressions where a screen forgets `context.kColors` and hard-paints
// a dark surface into the light theme.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/app/theme/kasyaba_color_scheme.dart';
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

const SavingsGoal _qaParityGoal = SavingsGoal(
  id: 'goal-parity-1',
  name: 'QA Parity Goal',
  targetAmount: 30000,
  currentAmount: 5000,
  targetDate: '2027-06-01',
  canAffordByTargetDate: true,
);

/// One routed screen and the harness configuration it needs.
class _ScreenCase {
  const _ScreenCase(
    this.name,
    this.build, {
    this.overrides,
    this.settle = true,
  });

  final String name;
  final Widget Function() build;
  final List<Override> Function()? overrides;

  /// Splash/Login/Register own indeterminate animations, so `pumpAndSettle`
  /// can never complete; the smoke harness pumps fixed frames instead.
  final bool settle;
}

void main() {
  final screens = <_ScreenCase>[
    _ScreenCase(
      'SplashScreen',
      () => const SplashScreen(),
      overrides: () => const <Override>[],
      settle: false,
    ),
    _ScreenCase(
      'LoginScreen',
      () => const LoginScreen(),
      settle: false,
    ),
    _ScreenCase(
      'RegisterScreen',
      () => const RegisterScreen(),
      settle: false,
    ),
    _ScreenCase(
      'ForgotPasswordScreen',
      () => const ForgotPasswordScreen(),
    ),
    _ScreenCase('DashboardScreen', () => const DashboardScreen()),
    _ScreenCase('PlanningScreen', () => const PlanningScreen()),
    _ScreenCase(
      'TransactionsScreen',
      () => const TransactionsScreen(),
    ),
    _ScreenCase('BillsScreen', () => const BillsScreen()),
    _ScreenCase('GoalsScreen', () => const GoalsScreen()),
    _ScreenCase('BudgetsScreen', () => const BudgetsScreen()),
    _ScreenCase('AlertsScreen', () => const AlertsScreen()),
    _ScreenCase('SettingsScreen', () => const SettingsScreen()),
    _ScreenCase('AccountsScreen', () => const AccountsScreen()),
    _ScreenCase(
      'NotificationSettingsScreen',
      () => const NotificationSettingsScreen(),
    ),
    _ScreenCase(
      'BackupExportScreen',
      () => const BackupExportScreen(),
      overrides: () => const <Override>[],
    ),
    _ScreenCase(
      'DeleteAccountScreen',
      () => const DeleteAccountScreen(),
      overrides: () => const <Override>[],
    ),
    _ScreenCase(
      'PrivacyAndAboutScreen',
      () => const PrivacyAndAboutScreen(),
      overrides: () => const <Override>[],
    ),
    _ScreenCase(
      'MathBreakdownScreen',
      () => const MathBreakdownScreen(),
    ),
    _ScreenCase(
      'AddTransactionScreen',
      () => const AddTransactionScreen(),
    ),
    _ScreenCase('AddBillScreen', () => const AddBillScreen()),
    _ScreenCase('CreateGoalScreen', () => const CreateGoalScreen()),
    _ScreenCase(
      'GoalDetailScreen',
      () => const GoalDetailScreen(
        goalId: 'goal-parity-1',
        initialGoal: _qaParityGoal,
      ),
      overrides: () => qaDefaultDataOverrides(
        goals: <SavingsGoal>[_qaParityGoal],
      ),
    ),
  ];

  for (final screen in screens) {
    for (final mode in <ThemeMode>[ThemeMode.dark, ThemeMode.light]) {
      final isLight = mode == ThemeMode.light;
      final modeLabel = isLight ? 'light' : 'dark';

      testWidgets('${screen.name} renders in $modeLabel mode', (tester) async {
        final harness = QaHarness();
        await harness.pumpScreen(
          tester,
          screen.build(),
          overrides: screen.overrides?.call() ?? qaDefaultDataOverrides(),
          settle: screen.settle,
          themeMode: mode,
        );

        if (!screen.settle) {
          // A fixed pump is enough to prove the first frame laid out cleanly
          // while indeterminate animations keep running.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.name} threw while building in $modeLabel mode.',
          );
          if (screen.name == 'SplashScreen') {
            expect(find.text('KASYABA'), findsOneWidget);
          }
        }

        _expectScaffoldCanvas(tester, isLight: isLight);
      });
    }
  }
}

/// Asserts the screen's scaffold resolves to the palette canvas in [isLight].
void _expectScaffoldCanvas(
  WidgetTester tester, {
  required bool isLight,
}) {
  final expectedBrightness =
      isLight ? Brightness.light : Brightness.dark;
  final expectedCanvas =
      isLight ? kasyabaLightColors.canvas : kasyabaDarkColors.canvas;

  // LT-E contract: the locked canvas values from the light-mode plan.
  expect(
    kasyabaLightColors.canvas,
    const Color(0xFFF6F8FB),
    reason: 'Light palette canvas must stay #F6F8FB.',
  );
  expect(
    kasyabaDarkColors.canvas,
    const Color(0xFF0A1220),
    reason: 'Dark palette canvas must stay #0A1220.',
  );

  final scaffoldFinder = find.byType(Scaffold);
  expect(
    scaffoldFinder,
    findsWidgets,
    reason: 'Routed screens are expected to own a Scaffold.',
  );

  final scaffold = tester.widget<Scaffold>(scaffoldFinder.first);
  final scaffoldContext = tester.element(scaffoldFinder.first);

  expect(
    Theme.of(scaffoldContext).brightness,
    expectedBrightness,
    reason: 'Theme.of(context).brightness should follow the pumped mode.',
  );

  final effectiveBackground =
      scaffold.backgroundColor ??
      Theme.of(scaffoldContext).scaffoldBackgroundColor;
  expect(
    effectiveBackground,
    expectedCanvas,
    reason: 'Scaffold background must use the ${isLight ? 'light' : 'dark'} '
        'palette canvas ($expectedCanvas), not a hard-painted surface.',
  );

  final materialColors = tester
      .widgetList<Material>(find.byType(Material))
      .map((material) => material.color)
      .toList(growable: false);
  expect(
    materialColors,
    contains(expectedCanvas),
    reason: 'At least one rendered Material should paint the '
        '${isLight ? 'light' : 'dark'} palette canvas ($expectedCanvas).',
  );
}
