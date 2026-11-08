import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/app/theme/kasyaba_color_scheme.dart';

/// Alpha-composites [foreground] over an opaque [background].
Color _blend(Color foreground, Color background) {
  final alpha = foreground.a;
  return Color.from(
    alpha: 1,
    red: foreground.r * alpha + background.r * (1 - alpha),
    green: foreground.g * alpha + background.g * (1 - alpha),
    blue: foreground.b * alpha + background.b * (1 - alpha),
  );
}

/// WCAG 2.1 relative luminance for an sRGB channel.
double _linearChannel(double channel) {
  return channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double relativeLuminance(Color color) {
  return 0.2126 * _linearChannel(color.r) +
      0.7152 * _linearChannel(color.g) +
      0.0722 * _linearChannel(color.b);
}

double contrastRatio(Color foreground, Color background) {
  final first = relativeLuminance(foreground);
  final second = relativeLuminance(background);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const palettes = <String, KasyabaColorScheme>{
    'dark': kasyabaDarkColors,
    'light': kasyabaLightColors,
  };

  group('WCAG text contrast', () {
    for (final entry in palettes.entries) {
      final name = entry.key;
      final colors = entry.value;

      test('$name: textPrimary on canvas >= 7:1', () {
        expect(
          contrastRatio(colors.textPrimary, colors.canvas),
          greaterThanOrEqualTo(7.0),
          reason: '$name primary text must hit AAA on the canvas.',
        );
      });

      test('$name: textSecondary on canvas >= 4.5:1', () {
        expect(
          contrastRatio(colors.textSecondary, colors.canvas),
          greaterThanOrEqualTo(4.5),
          reason: '$name secondary text must hit WCAG AA on the canvas.',
        );
      });

      test('$name: onPrimaryButton vs primaryButton >= 4.5:1', () {
        expect(
          contrastRatio(colors.onPrimaryButton, colors.primaryButton),
          greaterThanOrEqualTo(4.5),
          reason: '$name button label must hit WCAG AA on its fill.',
        );
      });

      test('$name: danger on canvas >= 4.5:1', () {
        expect(
          contrastRatio(colors.danger, colors.canvas),
          greaterThanOrEqualTo(4.5),
          reason: '$name danger text must hit WCAG AA on the canvas.',
        );
      });

      test('$name: danger label on dangerTint over card >= 4.5:1', () {
        final blended = _blend(colors.dangerTint, colors.card);
        expect(
          contrastRatio(colors.danger, blended),
          greaterThanOrEqualTo(4.5),
          reason: '$name destructive labels must be readable on their tint.',
        );
      });
    }

    // LT-B: light success/warning were darkened from the LOCKED
    // #2E8A63 (4.00:1) / #B7791F (3.42:1) values to #1F7A54 (4.97:1) and
    // #8A5A16 (5.55:1) so both palettes clear WCAG AA on the canvas.
    for (final entry in palettes.entries) {
      final name = entry.key;
      final colors = entry.value;

      test('$name: success/warning on canvas >= 4.5:1', () {
        expect(
          contrastRatio(colors.success, colors.canvas),
          greaterThanOrEqualTo(4.5),
          reason: '$name success must hit WCAG AA on the canvas.',
        );
        expect(
          contrastRatio(colors.warning, colors.canvas),
          greaterThanOrEqualTo(4.5),
          reason: '$name warning must hit WCAG AA on the canvas.',
        );
      });
    }
  });
}
