import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Motion & Haptics Engine — Tactile Kinematics System
///  Inspired by physical gadgets, mechanical counters, and spring physics.
/// ─────────────────────────────────────────────────────────────

class AppMotion {
  AppMotion._();

  // ── Standard Durations ──────────────────────────────────────
  /// Instant touch feedback (down-state compression, toggle flips)
  static const Duration touchDown = Duration(milliseconds: 100);

  /// Snappy spring release (button up-state, segmented pill slide)
  static const Duration snappy = Duration(milliseconds: 180);

  /// Bouncy physics settle (cards bouncing into place, sheet reveals)
  static const Duration bouncy = Duration(milliseconds: 320);

  /// Expressive choreographed transitions (rolling numbers, arc sweep)
  static const Duration expressive = Duration(milliseconds: 550);

  /// Stagger delay between adjacent list or grid items
  static const Duration stagger = Duration(milliseconds: 35);

  // ── Custom Kinematic Curves ─────────────────────────────────
  /// Standard overshoot spring curve for physical recoil
  static const Curve springRecoil = Cubic(0.34, 1.45, 0.64, 1.0);

  /// Gentle ease-out for entering items
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Bouncy curve with distinct overshoot
  static const Curve easeOutBack = Curves.easeOutBack;

  /// Smooth deceleration for bottom sheets and drawers
  static const Curve easeOutQuart = Curves.easeOutQuart;
}

/// Tactile Haptics Engine wrapper for consistent physical feedback
class AppHaptics {
  AppHaptics._();

  /// Subtle click for tab switches, segmented slider moves, or chip toggles
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Light tap for button presses, list tile taps, card compression
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium pulse for primary action completion (Save Expense, Transfer)
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Solid double pulse for milestone achievements (Goal Reached, Zero Discrepancy)
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}

