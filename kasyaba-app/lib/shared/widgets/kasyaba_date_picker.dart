import 'package:flutter/material.dart';

import '../../app/theme/kasyaba_color_scheme.dart';

/// Shared theme override for the Material date picker.
///
/// Follows the active app brightness so the picker renders a usable navy
/// surface in dark mode and a porcelain surface in light mode.
ThemeData kasyabaDatePickerTheme(BuildContext context) {
  final ThemeData base = Theme.of(context);
  final colors = context.kColors;
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      brightness: base.brightness,
      primary: colors.primaryButton,
      onPrimary: colors.onPrimaryButton,
      surface: colors.card,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.cardBorderStrong,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: colors.card,
    ),
  );
}
