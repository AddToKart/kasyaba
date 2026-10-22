import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'pressable_scale.dart';

/// ─────────────────────────────────────────────────────────────
///  ModernCard — Tactile Squircle Card Widget (Option C)
///  Adapts to Obsidian Dark & Porcelain Light with tactile spring physics.
/// ─────────────────────────────────────────────────────────────
enum CardStyle { glass, gradient, elevated, flat }

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
        (isDark ? AppColors.surfaceCard : AppColors.lightCardSurface);

    // Intelligently detect if this card surface is dark:
    final bool isSurfaceDark = gradient != null ||
        (backgroundColor != null
            ? backgroundColor!.computeLuminance() < 0.2
            : isDark);

    // Guaranteed guard against stark white outlines on dark surfaces:
    final effectiveBorder = borderColor != null
        ? (isSurfaceDark && (borderColor == AppColors.lightBorderHairline || borderColor == AppColors.lightBorder)
            ? AppColors.subtleBorder
            : borderColor!)
        : (isSurfaceDark ? AppColors.subtleBorder : AppColors.lightBorderHairline);
    final shadow = customShadow ?? _buildShadow(isDark);

    final radius = BorderRadius.circular(borderRadius);

    Widget innerChild = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    final decoration = BoxDecoration(
      borderRadius: radius,
      gradient: gradient,
      color: gradient == null ? effectiveBg : null,
      border: Border.all(color: effectiveBorder, width: 1),
      boxShadow: shadow,
    );

    final cardWidget = Container(
      decoration: decoration,
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: innerChild,
        ),
      ),
    );

    if (onTap != null) {
      return PressableScale(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  List<BoxShadow> _buildShadow(bool isDark) {
    switch (style) {
      case CardStyle.elevated:
        return [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x0C000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
      case CardStyle.flat:
      case CardStyle.gradient:
      case CardStyle.glass:
        return isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ];
    }
  }
}
