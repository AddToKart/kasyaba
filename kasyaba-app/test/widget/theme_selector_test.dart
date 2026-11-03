import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
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

  testWidgets('SettingsScreen shows real profile data and no theme selector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => testProfile),
          budgetStatusProvider.overrideWith(
            (ref) async => const BudgetStatus(
              month: '2026-11',
              totalBudget: 10000,
              totalSpent: 4200,
              overallPercent: 42,
              budgetCount: 1,
              budgets: [],
            ),
          ),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(
                isAuthenticated: true,
                userId: 'user-theme-test-1111',
                email: 'kurt@kasyaba.ph',
                displayName: 'Kurt C.',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Kurt C.'), findsOneWidget);
    expect(find.text('kurt@kasyaba.ph'), findsOneWidget);
    expect(find.text('Appearance & Theme'), findsNothing);
    expect(find.text('Choose your lighting atmosphere'), findsNothing);
    expect(find.text('Dark'), findsNothing);
    expect(find.text('Light'), findsNothing);
    expect(find.text('System'), findsNothing);

    expect(find.text('42% of budget used this month'), findsOneWidget);
  });
}
