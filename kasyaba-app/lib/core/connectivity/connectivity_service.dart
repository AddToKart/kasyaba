import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves a list of [ConnectivityResult] to a single result or null.
/// Returns `null` when the device has no connectivity (empty list or
/// [ConnectivityResult.none] present).
ConnectivityResult? _resolveConnectivity(List<ConnectivityResult> results) {
  if (results.isEmpty || results.contains(ConnectivityResult.none)) {
    return null;
  }
  return results.first;
}

/// A [StreamProvider] that emits the current connectivity status.
///
/// Performs an initial connectivity check on first subscription so the app
/// doesn't flash an "offline" indicator on startup, then listens to ongoing
/// connectivity changes via [Connectivity.onConnectivityChanged].
final connectivityStatusProvider = StreamProvider<ConnectivityResult?>((
  ref,
) async* {
  final connectivity = Connectivity();

  // Emit initial status immediately.
  final initialResults = await connectivity.checkConnectivity();
  yield _resolveConnectivity(initialResults);

  // Follow ongoing connectivity changes.
  await for (final results in connectivity.onConnectivityChanged) {
    yield _resolveConnectivity(results);
  }
});

/// A [Provider] that indicates whether the device is online.
///
/// Returns `true` when [connectivityStatusProvider] emits a non-null value
/// (the device has some form of network access).
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  // Connectivity is unknown while the first platform check is running. Treat
  // that state as online so startup requests (including auth restoration) are
  // not rejected before the check can complete.
  return status.when(
    data: (value) => value != null,
    loading: () => true,
    error: (_, _) => true,
  );
});

/// Performs a one-shot connectivity check.
///
/// Useful for places that need a single snapshot rather than a stream.
Future<bool> checkConnectivityOnce() async {
  final results = await Connectivity().checkConnectivity();
  return _resolveConnectivity(results) != null;
}
