import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  ModernBottomSheet — Sharp Obsidian Luxury Modal Sheet
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
      barrierColor: Colors.black.withValues(alpha: 0.8),
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.zero, // Sharp rectilinear top edge
        border: const Border(
          top: BorderSide(
            color: Color(0xFFD4AF37), // Hairline Champagne Gold border
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
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
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F293D),
                      borderRadius: BorderRadius.zero,
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
                            letterSpacing: 0.5,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
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
                  const _CloseButton(),
                ],
              ),
              const SizedBox(height: 20),

              // ── Divider ───────────────────────────────────
              const Divider(
                height: 1,
                color: Color(0xFF1F293D),
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
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: const Color(0xFF1F293D),
          width: 1,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: const Icon(
          Icons.close_rounded,
          color: AppColors.textMuted,
        ),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Close',
      ),
    );
  }
}
