import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  ModernBottomSheet — Luxury Frosted Modal Sheet
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
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.subtleBorder : AppColors.lightBorderHairline,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0x18000000),
            blurRadius: 16,
            offset: const Offset(0, -4),
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
              if (showDragHandle) ...[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface600 : const Color(0xFFD4D4D8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 8),
              ],

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
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (action != null) ...[action!, const SizedBox(width: 8)],
                  const _CloseButton(),
                ],
              ),
              const SizedBox(height: 20),

              Divider(height: 1, color: isDark ? AppColors.subtleBorder : AppColors.lightBorderHairline),
              const SizedBox(height: 20),

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
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'Close',
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface700 : AppColors.lightInputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.subtleBorder : AppColors.lightBorderHairline,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
