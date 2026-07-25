import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  ModernCard — Luxury glass-morphism card
/// ─────────────────────────────────────────────────────────────
enum CardStyle {
  /// Default glass card with subtle border
  glass,
  /// Vibrant filled gradient card
  gradient,
  /// Elevated card with deeper shadow
  elevated,
  /// Flat ultra-minimalist card
  flat,
}

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final CardStyle style;
  final List<BoxShadow>? customShadow;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.gradient,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 20.0,
    this.style = CardStyle.glass,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBg = backgroundColor ??
        (isDark ? AppColors.surfaceCard : AppColors.lightCard);

    final effectiveBorder = borderColor ??
        (isDark
            ? AppColors.surface600.withValues(alpha: 0.55)
            : AppColors.lightBorder.withValues(alpha: 0.85));

    final shadow = customShadow ?? _buildShadow(isDark);

    final radius = BorderRadius.circular(borderRadius);

    Widget innerChild =
        padding != null ? Padding(padding: padding!, child: child) : child;

    final decoration = BoxDecoration(
      borderRadius: radius,
      gradient: gradient,
      color: gradient == null ? effectiveBg : null,
      border: Border.all(color: effectiveBorder, width: 1),
      boxShadow: shadow,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Ink(
            decoration: decoration,
            child: ClipRRect(borderRadius: radius, child: innerChild),
          ),
        ),
      );
    }

    return Container(
      decoration: decoration,
      child: ClipRRect(borderRadius: radius, child: innerChild),
    );
  }

  List<BoxShadow> _buildShadow(bool isDark) {
    switch (style) {
      case CardStyle.elevated:
        return isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ];
      case CardStyle.flat:
        return [];
      case CardStyle.gradient:
      case CardStyle.glass:
        return isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ];
    }
  }
}
