import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Broadcasts "the refresh token is no longer valid" so the auth notifier can
/// force a local sign-out without the HTTP layer depending on auth state.
final sessionExpiredProvider = Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});
