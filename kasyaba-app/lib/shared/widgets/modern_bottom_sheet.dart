import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  ModernBottomSheet — Luxury frosted-glass modal bottom sheet
/// ─────────────────────────────────────────────────────────────
class ModernBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final bool showDragHandle;

  const ModernBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.action,
    this.showDragHandle = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
    Widget? action,
    bool showDragHandle = true,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      useRootNavigator: useRootNavigator,
      builder: (ctx) => ModernBottomSheet(
        title: title,
        subtitle: subtitle,
        action: action,
        showDragHandle: showDragHandle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.surface600.withValues(alpha: 0.7)
                : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Drag Handle ──────────────────────────────
              if (showDragHandle) ...[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface600
                          : AppColors.lightBorder2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 8),
              ],

              // ── Header Row ───────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (action != null) ...[
                    action!,
                    const SizedBox(width: 8),
                  ],
                  // Close Button
                  _CloseButton(isDark: isDark),
                ],
              ),
              const SizedBox(height: 20),

              // ── Divider ───────────────────────────────────
              Divider(
                height: 1,
                color: isDark
                    ? AppColors.surface600.withValues(alpha: 0.5)
                    : AppColors.lightBorder.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 20),

              // ── Content ──────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: child,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final bool isDark;
  const _CloseButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface700.withValues(alpha: 0.8)
            : AppColors.lightCard2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.surface600 : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(
          Icons.close_rounded,
          color: isDark ? AppColors.textMuted : AppColors.textMutedL,
        ),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Close',
      ),
    );
  }
}
