import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  EmptyStateView — Sharp Luxury Empty State Widget
/// ─────────────────────────────────────────────────────────────
class EmptyStateView extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.emerald500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Layered Icon Container ───────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 28, color: accent),
            ),

            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: isDark ? AppColors.textDark : AppColors.lightTextPrimary,
              ),
            ),

            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textMuted : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),
            ],

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(140, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
