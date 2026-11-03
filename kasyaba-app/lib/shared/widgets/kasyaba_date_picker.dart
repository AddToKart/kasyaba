import 'package:flutter/material.dart';

import '../../app/theme/kasyaba_tokens.dart';

/// Shared theme override for the Material date picker (dark navy).
ThemeData kasyabaDatePickerTheme(BuildContext context) {
  final ThemeData base = Theme.of(context);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: KasyabaTokens.periwinkleGray,
      onPrimary: KasyabaTokens.ebony,
      surface: KasyabaTokens.bigStone,
      onSurface: KasyabaTokens.periwinkleGray,
      onSurfaceVariant: KasyabaTokens.periwinkleGraySubtitle,
      outline: KasyabaTokens.poloBlue30,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: KasyabaTokens.bigStone,
    ),
  );
}
