import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../database/cache_service.dart';
import 'api_providers.dart';

/// Invalidates every finance-data provider that can outlive a session.
///
/// Finance providers are kept alive, so without this a newly signed-in user
/// would keep seeing the previous user's cached bills, dashboard, etc.
void invalidateFinanceData(Ref ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(paginatedTransactionsProvider);
  ref.invalidate(transactionsProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(accountsProvider);
  ref.invalidate(accountBalancesProvider);
  ref.invalidate(planningProvider);
  ref.invalidate(budgetStatusProvider);
  ref.invalidate(goalsProvider);
  ref.invalidate(goalDetailProvider);
  ref.invalidate(billsProvider);
  ref.invalidate(userProfileProvider);
  ref.read(transactionFilterProvider.notifier).state =
      const TransactionQueryFilter(page: 1, limit: 50);
}

/// Resets all finance-data providers whenever the authenticated user changes
/// (login, logout, account switch, or session expiry).
final sessionDataResetProvider = Provider<void>((ref) {
  ref.listen<String?>(authProvider.select((s) => s.userId), (prev, next) {
    if (prev == next) return;
    invalidateFinanceData(ref);
    // Retention (D4): sign-out and session expiry clear read snapshots for
    // the user who just left, but the offline queue survives so captured
    // mutations are not silently lost.
    if (next == null && prev != null) {
      unawaited(
        ref
            .read(cacheServiceProvider)
            .deleteSnapshotsFor(prev)
            .catchError((_) {}),
      );
    }
  });
});

/// Refreshes server-derived data when the app returns to the foreground so
/// hourly generation and overdue flips surface without a restart.
void invalidateOnResume(WidgetRef ref) {
  ref.invalidate(billsProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(planningProvider);
  ref.invalidate(accountBalancesProvider);
  ref.invalidate(budgetStatusProvider);
}
