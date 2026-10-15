import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_provider.dart';
import '../connectivity/connectivity_service.dart';
import '../providers/api_providers.dart';
import 'cache_service.dart';

/// Keeps the small local mutation queue moving after connectivity returns.
/// The provider is watched by the app root so it remains active for the whole
/// authenticated session.
final offlineSyncProvider = Provider<void>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  final dio = ref.watch(dioProvider);
  var syncing = false;

  Future<void> sync() async {
    if (syncing || !ref.read(isOnlineProvider)) return;
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;

    syncing = true;
    try {
      final synced = await cache.syncPendingTransactions(dio, userId);
      if (synced > 0) {
        ref.invalidate(dashboardProvider);
        ref.invalidate(paginatedTransactionsProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(accountsProvider);
      }
    } finally {
      syncing = false;
    }
  }

  unawaited(sync());
  ref.listen(connectivityStatusProvider, (_, next) {
    if (next.valueOrNull != null) unawaited(sync());
  });
  ref.listen(authProvider, (_, next) {
    if (next.isAuthenticated) unawaited(sync());
  });
});
