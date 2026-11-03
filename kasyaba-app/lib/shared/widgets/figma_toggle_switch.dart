import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/dashboard/widgets/dashboard_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Figma 1:1 Luxury Pill Toggle Switch (Width: 52, Height: 32)
/// ─────────────────────────────────────────────────────────────
class FigmaToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const FigmaToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value
              ? DashboardTokens.periwinkleGray
              : DashboardTokens.poloBlue25,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value
                  ? DashboardTokens.ebony
                  : DashboardTokens.periwinkleGraySubtitle,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

