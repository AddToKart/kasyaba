import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_motion.dart';
import '../../features/dashboard/widgets/dashboard_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Toast / Alert Card
///  Design System Aligned Floating Notification Banner
/// ─────────────────────────────────────────────────────────────
class KasyabaToast {
  KasyabaToast._();

  static const double defaultDockClearance = 105.0;

  /// Show a success toast (e.g. Income recorded, Expense recorded, Transfer saved)
  static void showSuccess(
    BuildContext context,
    String message, {
    String? subtitle,
    double bottomMargin = defaultDockClearance,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppHaptics.lightImpact();
    _show(
      context,
      message: message,
      subtitle: subtitle,
      icon: Icons.check_circle_rounded,
      accentColor: DashboardTokens.bermuda,
      bottomMargin: bottomMargin,
      duration: duration,
    );
  }

  /// Show an error or warning toast (e.g. Validation error, API failure)
  static void showError(
    BuildContext context,
    String message, {
    String? subtitle,
    double bottomMargin = defaultDockClearance,
    Duration duration = const Duration(seconds: 4),
  }) {
    AppHaptics.heavyImpact();
    _show(
      context,
      message: message,
      subtitle: subtitle,
      icon: Icons.error_outline_rounded,
      accentColor: DashboardTokens.apricot,
      bottomMargin: bottomMargin,
      duration: duration,
    );
  }

  /// Show an info or sync status toast (e.g. Queued for offline sync)
  static void showInfo(
    BuildContext context,
    String message, {
    String? subtitle,
    IconData icon = Icons.info_outline_rounded,
    Color? accentColor,
    double bottomMargin = defaultDockClearance,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppHaptics.selectionClick();
    _show(
      context,
      message: message,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor ?? DashboardTokens.poloBlue,
      bottomMargin: bottomMargin,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    String? subtitle,
    required IconData icon,
    required Color accentColor,
    required double bottomMargin,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DashboardTokens.poloBlue22,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: DashboardTokens.periwinkleGraySubtitle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
