import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/kasyaba_color_scheme.dart';

enum PillButtonVariant { primary, secondary, destructive }

/// Canonical pill CTA used across the app.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final bool expand;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? fontSize;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 56,
    this.expand = true,
    this.padding,
    this.borderRadius,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    final Color fill;
    final Color? border;
    final Color foreground;

    switch (variant) {
      case PillButtonVariant.primary:
        fill = colors.primaryButton;
        border = null;
        foreground = colors.onPrimaryButton;
      case PillButtonVariant.secondary:
        fill = Colors.transparent;
        border = colors.secondaryBorder;
        foreground = colors.textPrimary;
      case PillButtonVariant.destructive:
        fill = colors.dangerTint;
        border = colors.danger;
        foreground = colors.danger;
    }

    final bool isEnabled = onPressed != null && !isLoading;

    final Widget content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: foreground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: foreground,
                    fontSize: fontSize ?? 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          );

    final effectivePadding = padding ??
        (expand ? null : const EdgeInsets.symmetric(horizontal: 20));

    final Widget button = Container(
      height: height,
      width: expand ? double.infinity : null,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(
          borderRadius ?? (height / 2),
        ),
        border: border == null ? null : Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: Center(child: content),
        ),
      ),
    );

    return Opacity(
      opacity: (onPressed == null && !isLoading) ? 0.5 : 1.0,
      child: button,
    );
  }
}
