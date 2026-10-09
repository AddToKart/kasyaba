import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/transactions/screens/add_transaction_screen.dart';
import '../../features/transactions/screens/add_transfer_screen.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/planning/screens/planning_screen.dart';
import '../../features/budgets/screens/budgets_screen.dart';
import '../../features/savings/screens/goals_screen.dart';
import '../../features/bills/screens/bills_screen.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/providers/api_providers.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isInitializing = authState.isInitializing;
      final isLoggedIn = authState.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

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
      // Persistent App Shell containing bottom navigation bar
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/bills',
            builder: (context, state) => const BillsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
        ],
      ),
      // Sub-routes without bottom navigation bar
      GoRoute(
        path: '/transactions/add',
        builder: (context, state) =>
            AddTransactionScreen(initialType: state.extra as String?),
      ),
      GoRoute(
        path: '/transactions/edit',
        builder: (context, state) {
          final transaction = state.extra;
          if (transaction is! TransactionEntry) {
            return const Scaffold(
              body: Center(child: Text('Transaction details unavailable.')),
            );
          }
          return AddTransactionScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: '/transfers/add',
        builder: (context, state) => const AddTransferScreen(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/planning',
        builder: (context, state) => const PlanningScreen(),
      ),
    ],
  );
});
