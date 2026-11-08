import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/theme_provider.dart';
import 'package:kasyaba/features/settings/screens/settings_screen.dart';

import 'support/qa_harness.dart';

void main() {
  testWidgets('Appearance selector updates themeModeProvider and persists', (
    tester,
  ) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const SettingsScreen(),
      overrides: qaDefaultDataOverrides(),
    );

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    // D-LT2: the row starts on the dark default.
    expect(find.text('Dark'), findsOneWidget);

    await qaTapVisible(tester, find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(find.text('Choose how Kasyaba looks on this device.'), findsOneWidget);
    expect(find.text('Dark'), findsWidgets);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(harness.storage.values['app_theme_mode'], 'light');
    // The Appearance row subtitle reflects the choice immediately.
    expect(find.text('Light'), findsOneWidget);

    await qaTapVisible(tester, find.text('Appearance'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(harness.storage.values['app_theme_mode'], 'system');
    expect(find.text('System (follow device)'), findsOneWidget);
  });

  testWidgets('stored appearance is honored on startup', (tester) async {
    final harness = QaHarness();
    harness.storage.values['app_theme_mode'] = 'system';

    await harness.pumpScreen(
      tester,
      const SettingsScreen(),
      overrides: qaDefaultDataOverrides(),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );

    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
