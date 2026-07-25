import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  ModernCard — Sharp Luxury Rectilinear Card
/// ─────────────────────────────────────────────────────────────
enum CardStyle {
  glass,
  gradient,
  elevated,
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
    this.borderRadius = 0.0, // Sharp rectilinear default
    this.style = CardStyle.glass,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBg = backgroundColor ?? AppColors.surfaceCard;
    final effectiveBorder = borderColor ?? const Color(0xFF1F293D);
    final shadow = customShadow ?? _buildShadow(isDark);

    final radius = borderRadius > 0 ? BorderRadius.circular(borderRadius) : BorderRadius.zero;

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
          splashColor: AppColors.gold500.withValues(alpha: 0.1),
          highlightColor: AppColors.gold500.withValues(alpha: 0.05),
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
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];
      case CardStyle.flat:
        return [];
      case CardStyle.gradient:
      case CardStyle.glass:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
    }
  }
}
