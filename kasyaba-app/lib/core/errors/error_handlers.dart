import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/kasyaba_color_scheme.dart';

/// Installs app-wide error capture so framework and platform errors are logged
/// instead of silently degrading, and replaces the release "red screen" with a
/// friendly fallback. Wire a crash reporter (Sentry/Crashlytics) into these
/// handlers when available.
void installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(
      '[FlutterError] ${details.exceptionAsString()}\n${details.stack}',
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[UncaughtError] $error\n$stack');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return const _FriendlyErrorWidget();
  };
}

class _FriendlyErrorWidget extends StatelessWidget {
  const _FriendlyErrorWidget();

  @override
  Widget build(BuildContext context) {
    // No Theme may be available when an error widget renders, so derive the
    // palette straight from the platform brightness.
    final brightness = WidgetsBinding
        .instance.platformDispatcher.platformBrightness;
    final colors = brightness == Brightness.dark
        ? kasyabaDarkColors
        : kasyabaLightColors;

    return Material(
      color: colors.canvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colors.textSecondary,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong on this screen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please go back and try again. If it keeps happening, restart the app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
