import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  ModernCard — Ultra Luxury Glass & Metallic Card Widget
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
    final effectiveBg = backgroundColor ?? AppColors.surfaceCard;
    final effectiveBorder = borderColor ?? AppColors.subtleBorder;
    final shadow = customShadow ?? _buildShadow();

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

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.emerald500.withValues(alpha: 0.12),
          highlightColor: AppColors.emerald500.withValues(alpha: 0.05),
          child: Ink(
            decoration: decoration,
            child: ClipRRect(borderRadius: radius, child: innerChild),
          ),
        ),
      );
    }

    return Container(
      decoration: decoration,
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: innerChild,
        ),
      ),
    );
  }

  List<BoxShadow> _buildShadow() {
    switch (style) {
      case CardStyle.elevated:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      case CardStyle.flat:
        return [];
      case CardStyle.gradient:
      case CardStyle.glass:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
    }
  }
}
