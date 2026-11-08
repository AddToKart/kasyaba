// LT-C system surfaces (splash, dock, date picker) must resolve their colors
// from the active semantic palette in both dark and light modes.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/app/router/app_shell.dart';
import 'package:kasyaba/app/theme/app_theme.dart';
import 'package:kasyaba/app/theme/kasyaba_color_scheme.dart';
import 'package:kasyaba/features/splash/screens/splash_screen.dart';
import 'package:kasyaba/shared/widgets/kasyaba_date_picker.dart';

Widget _themed(ThemeMode mode, Widget home) {
  return MaterialApp(
    theme: AppTheme().light,
    darkTheme: AppTheme().dark,
    themeMode: mode,
    home: home,
  );
}

Map<ThemeMode, KasyabaColorScheme> get _palettes => <ThemeMode,
    KasyabaColorScheme>{
      ThemeMode.dark: kasyabaDarkColors,
      ThemeMode.light: kasyabaLightColors,
    };

BoxDecoration? _decorationOf(Widget widget) {
  if (widget is Container) return widget.decoration as BoxDecoration?;
  if (widget is AnimatedContainer) {
    return widget.decoration as BoxDecoration?;
  }
  return null;
}

void main() {
  for (final entry in _palettes.entries) {
    final mode = entry.key;
    final colors = entry.value;

    testWidgets('splash resolves ${mode.name} semantic surfaces', (
      tester,
    ) async {
      await tester.pumpWidget(_themed(mode, const SplashScreen()));
      // The splash owns an indeterminate progress indicator; a fixed pump is
      // enough to lay out the first frame.
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, colors.canvas);

      final title = tester.widget<Text>(find.text('KASYABA'));
      expect(title.style?.color, colors.textPrimary);

      final loader = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(loader.color, colors.primaryButton);

      final logoCircle = tester.widgetList<Container>(
        find.byType(Container),
      ).firstWhere((container) {
        final decoration = container.decoration as BoxDecoration?;
        return decoration?.shape == BoxShape.circle;
      });
      final circleDecoration = logoCircle.decoration as BoxDecoration;
      expect(circleDecoration.color, colors.canvas);
      expect(
        (circleDecoration.border as Border).top.color,
        colors.cardBorder,
      );
    });

    testWidgets('dock uses ${mode.name} tokens and renders all nav SVGs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          const AppShell(location: '/dashboard', child: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsNWidgets(5));
      expect(
        find.byType(ColorFiltered),
        findsNWidgets(5),
        reason: 'Every dock SVG is tinted through a ColorFiltered wrapper.',
      );

      final dock = tester.widgetList<Container>(find.byType(Container))
          .firstWhere(
            (container) => _decorationOf(container)?.color == colors.dockFill,
          );
      final dockDecoration = _decorationOf(dock)!;
      expect(
        (dockDecoration.border as Border).top.color,
        colors.dockBorder,
      );

      final selectedPills = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where(
            (pill) =>
                _decorationOf(pill)?.color == colors.primaryButton,
          );
      expect(selectedPills, hasLength(1));

      final home = tester.widget<Text>(find.text('Home'));
      expect(home.style?.color, colors.onPrimaryButton);

      final activity = tester.widget<Text>(find.text('Activity'));
      expect(activity.style?.color, colors.textSecondary);
    });

    testWidgets('date picker theme follows ${mode.name} brightness', (
      tester,
    ) async {
      late ThemeData captured;
      await tester.pumpWidget(
        _themed(
          mode,
          Builder(
            builder: (context) {
              captured = kasyabaDatePickerTheme(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final scheme = captured.colorScheme;
      expect(
        scheme.brightness,
        mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      );
      expect(scheme.primary, colors.primaryButton);
      expect(scheme.onPrimary, colors.onPrimaryButton);
      expect(scheme.surface, colors.card);
      expect(scheme.onSurface, colors.textPrimary);
      expect(scheme.onSurfaceVariant, colors.textSecondary);
      expect(scheme.outline, colors.cardBorderStrong);
      expect(captured.dialogTheme.backgroundColor, colors.card);
    });
  }
}
