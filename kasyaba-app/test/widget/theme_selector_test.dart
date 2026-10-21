import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/providers/theme_provider.dart';
import 'package:kasyaba/features/settings/screens/settings_screen.dart';

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const testProfile = UserProfile(
    id: 'user-theme-test-1111',
    email: 'kurt@kasyaba.ph',
    displayName: 'Kurt C.',
    salaryAmount: 50000.0,
    paydayFrequency: 'semi-monthly',
    paydaySchedule: '15th & 30th',
    minimumBalanceThreshold: 2000.0,
  );

  testWidgets('SettingsScreen renders Theme Selector and updates themeModeProvider',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => testProfile),
          authProvider.overrideWith((ref) => FakeAuthNotifier(const AuthState(
                isAuthenticated: true,
                userId: 'user-theme-test-1111',
                email: 'kurt@kasyaba.ph',
                displayName: 'Kurt C.',
              ))),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const SettingsScreen();
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Appearance & Theme Card is present
    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('Choose your lighting atmosphere'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Initial default theme mode should be dark
    expect(capturedRef.read(themeModeProvider), ThemeMode.dark);

    // Tap 'Light' button
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    // Verify theme mode updated to light
    expect(capturedRef.read(themeModeProvider), ThemeMode.light);

    // Tap 'System' button
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    // Verify theme mode updated to system
    expect(capturedRef.read(themeModeProvider), ThemeMode.system);

    // Tap 'Dark' button
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Verify theme mode updated back to dark
    expect(capturedRef.read(themeModeProvider), ThemeMode.dark);
  });
}
