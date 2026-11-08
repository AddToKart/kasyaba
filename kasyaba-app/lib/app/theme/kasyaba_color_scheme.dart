import 'package:flutter/material.dart';

import 'kasyaba_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Semantic Color Scheme — dual-palette (LT-A).
///
///  Dark values are the exact legacy [KasyabaTokens] values so the
///  frozen navy redesign does not change visually. Light values are the
///  locked porcelain palette from LIGHT_MODE_AND_GOAL_INPUT_PLAN §2.3.
/// ─────────────────────────────────────────────────────────────
abstract class KasyabaColorScheme {
  const KasyabaColorScheme();

  Color get canvas;
  RadialGradient get backgroundGradient;
  Color get card;
  Color get cardHero;
  Color get cardBorder;
  Color get cardBorderStrong;
  Color get divider;
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get icon;
  Color get primaryButton;
  Color get onPrimaryButton;
  Color get secondaryBorder;
  Color get success;
  Color get successTint;
  Color get warning;
  Color get warningTint;
  Color get danger;
  Color get dangerTint;
  Color get accentViolet;
  Color get accentTeal;
  Color get dockFill;
  Color get dockBorder;
  Color get inputFill;
  Color get inputBorder;
  Color get skeletonFill;
  Color get scrim;
  Color get shadow;
}

/// Exact dark mapping of the current [KasyabaTokens] navy system.
class KasyabaColorsDark extends KasyabaColorScheme {
  const KasyabaColorsDark();

  @override
  Color get canvas => KasyabaTokens.ebony;

  @override
  RadialGradient get backgroundGradient => KasyabaTokens.canvasGradient;

  @override
  Color get card => KasyabaTokens.bigStone;

  @override
  Color get cardHero => KasyabaTokens.cello60;

  @override
  Color get cardBorder => KasyabaTokens.poloBlue22;

  @override
  Color get cardBorderStrong => KasyabaTokens.poloBlue30;

  @override
  Color get divider => KasyabaTokens.poloBlue16;

  @override
  Color get textPrimary => KasyabaTokens.periwinkleGray;

  @override
  Color get textSecondary => KasyabaTokens.periwinkleGraySubtitle;

  @override
  Color get textMuted => KasyabaTokens.baliHai;

  @override
  Color get icon => KasyabaTokens.poloBlue;

  @override
  Color get primaryButton => KasyabaTokens.periwinkleGray;

  @override
  Color get onPrimaryButton => KasyabaTokens.ebony;

  @override
  Color get secondaryBorder => KasyabaTokens.kashmirBlue;

  @override
  Color get success => KasyabaTokens.bermuda;

  @override
  Color get successTint => KasyabaTokens.bermuda15;

  @override
  Color get warning => KasyabaTokens.casablanca;

  @override
  Color get warningTint => KasyabaTokens.casablanca15;

  @override
  Color get danger => KasyabaTokens.apricot;

  @override
  Color get dangerTint => KasyabaTokens.apricot15;

  @override
  Color get accentViolet => KasyabaTokens.cornflowerBlue;

  @override
  Color get accentTeal => KasyabaTokens.java;

  @override
  Color get dockFill => KasyabaTokens.ebony85;

  @override
  Color get dockBorder => KasyabaTokens.poloBlue30;

  @override
  Color get inputFill => KasyabaTokens.bigStone;

  @override
  Color get inputBorder => KasyabaTokens.poloBlue22;

  // bigStone at 50% opacity.
  @override
  Color get skeletonFill => const Color(0x8016293F);

  @override
  Color get scrim => const Color(0xB8000000);

  @override
  Color get shadow => const Color(0xFF000000);
}

/// Locked porcelain light palette (LIGHT_MODE_AND_GOAL_INPUT_PLAN §2.3).
///
/// LT-B revised `success` and `warning` to darker AA-safe values
/// (`#1F7A54` = 4.97:1 and `#8A5A16` = 5.55:1 on the canvas) while keeping
/// every other locked value untouched. Tints remain 14% of the base color.
class KasyabaColorsLight extends KasyabaColorScheme {
  const KasyabaColorsLight();

  @override
  Color get canvas => const Color(0xFFF6F8FB);

  @override
  RadialGradient get backgroundGradient => const RadialGradient(
        center: Alignment(0.8, -1.0),
        radius: 1.4,
        colors: <Color>[Color(0x599DB8D2), Color(0x009DB8D2)],
        stops: <double>[0.0, 0.7],
      );

  @override
  Color get card => const Color(0xFFFFFFFF);

  @override
  Color get cardHero => const Color(0xFFEFF5FA);

  @override
  Color get cardBorder => const Color(0xFFDCE5EE);

  @override
  Color get cardBorderStrong => const Color(0xFFC6D4E3);

  @override
  Color get divider => const Color(0xFFE7EDF4);

  @override
  Color get textPrimary => const Color(0xFF0D1826);

  @override
  Color get textSecondary => const Color(0xFF5A6E85);

  @override
  Color get textMuted => const Color(0xFF7C8FA3);

  @override
  Color get icon => const Color(0xFF6B8299);

  @override
  Color get primaryButton => const Color(0xFF4F7596);

  @override
  Color get onPrimaryButton => const Color(0xFFFFFFFF);

  @override
  Color get secondaryBorder => const Color(0xFF4F7596);

  @override
  Color get success => const Color(0xFF1F7A54);

  @override
  Color get successTint => const Color(0x241F7A54);

  @override
  Color get warning => const Color(0xFF8A5A16);

  @override
  Color get warningTint => const Color(0x248A5A16);

  @override
  Color get danger => const Color(0xFFB03A32);

  @override
  Color get dangerTint => const Color(0x24B03A32);

  @override
  Color get accentViolet => const Color(0xFF6E5BFF);

  @override
  Color get accentTeal => const Color(0xFF138D82);

  @override
  Color get dockFill => const Color(0xEBFFFFFF);

  @override
  Color get dockBorder => const Color(0xFFDCE5EE);

  @override
  Color get inputFill => const Color(0xFFF1F5F9);

  @override
  Color get inputBorder => const Color(0xFFDCE5EE);

  @override
  Color get skeletonFill => const Color(0x80E9EFF6);

  @override
  Color get scrim => const Color(0xB8000000);

  @override
  Color get shadow => const Color(0x140D1826);
}

const KasyabaColorScheme kasyabaDarkColors = KasyabaColorsDark();
const KasyabaColorScheme kasyabaLightColors = KasyabaColorsLight();

/// [ThemeExtension] that carries the active semantic palette and makes it
/// available through [KasyabaThemeContext.kColors].
class KasyabaThemeExt extends ThemeExtension<KasyabaThemeExt> {
  const KasyabaThemeExt({required this.colors});

  final KasyabaColorScheme colors;

  @override
  KasyabaThemeExt copyWith({KasyabaColorScheme? colors}) {
    return KasyabaThemeExt(colors: colors ?? this.colors);
  }

  @override
  KasyabaThemeExt lerp(covariant KasyabaThemeExt? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension KasyabaThemeContext on BuildContext {
  KasyabaColorScheme get kColors =>
      Theme.of(this).extension<KasyabaThemeExt>()?.colors ??
      const KasyabaColorsDark();
}
