import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/kasyaba_color_scheme.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/new_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/transactions/screens/add_transaction_screen.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/planning/screens/planning_screen.dart';
import '../../features/planning/screens/math_breakdown_screen.dart';
import '../../core/utils/deterministic_math.dart';
import '../../features/budgets/screens/budgets_screen.dart';
import '../../features/savings/screens/goals_screen.dart';
import '../../features/savings/screens/create_goal_screen.dart';
import '../../features/savings/screens/goal_detail_screen.dart';
import '../../features/bills/screens/bills_screen.dart';
import '../../features/bills/screens/add_bill_screen.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/settings/screens/backup_export_screen.dart';
import '../../features/settings/screens/delete_account_screen.dart';
import '../../features/settings/screens/privacy_about_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../shared/widgets/motion_components.dart';
import '../../shared/widgets/app_state_widgets.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/providers/api_providers.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
  final isInitializing =
      ref.watch(authProvider.select((s) => s.isInitializing));

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/otp-verification' ||
          state.matchedLocation == '/new-password';

      // Hold the app on the splash screen until the stored session has been
      // resolved so authenticated users never see a login flash.
      if (isInitializing) return isSplash ? null : '/splash';
      if (isSplash) return isLoggedIn ? '/dashboard' : '/login';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email =
              (extra?['email'] as String?) ??
              state.uri.queryParameters['email'] ??
              '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/new-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email =
              (extra?['email'] as String?) ??
              state.uri.queryParameters['email'] ??
              '';
          final resetToken =
              (extra?['resetToken'] as String?) ??
              state.uri.queryParameters['token'] ??
              '';
          return NewPasswordScreen(email: email, resetToken: resetToken);
        },
      ),
      // Persistent App Shell containing bottom navigation bar
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                MotionPageTransitions.fadeTransition(
                  key: state.pageKey,
                  child: const DashboardScreen(),
                ),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) =>
                MotionPageTransitions.fadeTransition(
                  key: state.pageKey,
                  child: const TransactionsScreen(),
                ),
          ),
          GoRoute(
            path: '/planning',
            pageBuilder: (context, state) =>
                MotionPageTransitions.fadeTransition(
                  key: state.pageKey,
                  child: const PlanningScreen(),
                ),
          ),
          GoRoute(
            path: '/planning/breakdown',
            pageBuilder: (context, state) {
              final extraCalc = state.extra as DailySafeSpendCalculation?;
              return MotionPageTransitions.slideUpTransition(
                key: state.pageKey,
                child: MathBreakdownScreen(calculation: extraCalc),
              );
            },
          ),
          GoRoute(
            path: '/goals',
            pageBuilder: (context, state) =>
                MotionPageTransitions.fadeTransition(
                  key: state.pageKey,
                  child: const GoalsScreen(),
                ),
          ),
          GoRoute(
            path: '/bills',
            pageBuilder: (context, state) =>
                MotionPageTransitions.fadeTransition(
                  key: state.pageKey,
                  child: const BillsScreen(),
                ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                MotionPageTransitions.fadeTransition(
                  key: state.pageKey,
                  child: const SettingsScreen(),
                ),
          ),
          GoRoute(
            path: '/budgets',
            pageBuilder: (context, state) =>
                MotionPageTransitions.fadeTransition(
                  key: state.pageKey,
                  child: const BudgetsScreen(),
                ),
          ),
          GoRoute(
            path: '/alerts',
            pageBuilder: (context, state) =>
                MotionPageTransitions.fadeTransition(
                  key: state.pageKey,
                  child: const AlertsScreen(),
                ),
          ),
        ],
      ),
      // Sub-routes without bottom navigation bar
      GoRoute(
        path: '/transactions/add',
        pageBuilder: (context, state) =>
            MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: AddTransactionScreen(initialType: state.extra as String?),
            ),
      ),
      GoRoute(
        path: '/transactions/edit',
        pageBuilder: (context, state) {
          final transaction = state.extra;
          if (transaction is! TransactionEntry) {
            return MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: Builder(
                builder: (context) => Scaffold(
                  backgroundColor: context.kColors.canvas,
                  body: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: KasyabaErrorCard(
                          message: 'Transaction details unavailable.',
                          retryLabel: 'Back to transactions',
                          onRetry: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/transactions');
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return MotionPageTransitions.slideUpTransition(
            key: state.pageKey,
            child: AddTransactionScreen(transaction: transaction),
          );
        },
      ),
      GoRoute(
        path: '/accounts',
        pageBuilder: (context, state) =>
            MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: const AccountsScreen(),
            ),
      ),
      GoRoute(
        path: '/settings/notifications',
        pageBuilder: (context, state) =>
            MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: const NotificationSettingsScreen(),
            ),
      ),
      GoRoute(
        path: '/settings/backup',
        pageBuilder: (context, state) =>
            MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: const BackupExportScreen(),
            ),
      ),
      GoRoute(
        path: '/settings/delete-account',
        pageBuilder: (context, state) =>
            MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: const DeleteAccountScreen(),
            ),
      ),
      GoRoute(
        path: '/settings/privacy',
        pageBuilder: (context, state) =>
            MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: const PrivacyAndAboutScreen(),
            ),
      ),
      GoRoute(
        path: '/bills/add',
        pageBuilder: (context, state) =>
            MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: AddBillScreen(initialName: state.extra as String?),
            ),
      ),
      GoRoute(
        path: '/goals/new',
        pageBuilder: (context, state) =>
            MotionPageTransitions.slideUpTransition(
              key: state.pageKey,
              child: CreateGoalScreen(
                existingGoal: state.extra as SavingsGoal?,
              ),
            ),
      ),
      GoRoute(
        path: '/goals/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MotionPageTransitions.slideUpTransition(
            key: state.pageKey,
            child: GoalDetailScreen(
              goalId: id,
              initialGoal: state.extra as SavingsGoal?,
            ),
          );
        },
      ),
    ],
  );
});
