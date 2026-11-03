import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/accounts/screens/accounts_screen.dart';
import 'package:kasyaba/features/settings/screens/notification_settings_screen.dart';
import 'package:kasyaba/features/settings/screens/delete_account_screen.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final testAccounts = [
    const Account(
      id: 'acc-1',
      name: 'Cash Wallet',
      type: 'cash',
    ),
    const Account(
      id: 'acc-2',
      name: 'GCash',
      type: 'ewallet',
    ),
  ];

  group('1:1 Figma Profile Suite Tests', () {
    testWidgets('AccountsScreen renders 1:1 Figma layout, balance hero, and Safe-to-Spend toggles', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsProvider.overrideWith((ref) async => testAccounts),
            accountBalancesProvider.overrideWith((ref) async => {
                  'acc-1': 825149.80,
                  'acc-2': 0.0,
                }),
          ],
          child: const MaterialApp(
            home: AccountsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Hero
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Total across accounts'), findsOneWidget);
      expect(find.text('₱825,149.80'), findsWidgets);

      // Verify Accounts List
      expect(find.text('Cash Wallet'), findsOneWidget);
      expect(find.text('Cash on hand'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('E-wallet'), findsOneWidget);

      // Verify Safe to spend toggles and Footnote
      expect(find.text('Count in safe to spend'), findsNWidgets(2));
      expect(
        find.text(
          'Accounts you switch on are counted in your Safe to spend. Switch one off to keep it out, for example savings you do not want to touch.',
        ),
        findsOneWidget,
      );

      // Verify Add account CTA
      expect(find.text('Add account'), findsOneWidget);
    });

    testWidgets('NotificationSettingsScreen renders 1:1 Figma notifications, groups, and time picker', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.text('Notifications'), findsOneWidget);

      // Group 1
      expect(find.text('Bill reminders'), findsOneWidget);
      expect(find.text('Before each bill is due'), findsOneWidget);
      expect(find.text('Remind me '), findsOneWidget);
      expect(find.text('3 days before'), findsOneWidget);
      expect(find.text('Budget alerts'), findsOneWidget);
      expect(find.text('At 80% and when you go over'), findsOneWidget);
      expect(find.text('Payday reminder'), findsOneWidget);
      expect(find.text('On the 15th and 30th'), findsOneWidget);

      // Group 2
      expect(find.text('Goal milestones'), findsOneWidget);
      expect(find.text('When a goal reaches 25%, 50%, 75%'), findsOneWidget);
      expect(find.text('Weekly summary'), findsOneWidget);
      expect(find.text('Every Sunday evening'), findsOneWidget);

      // Time picker row & footnote
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(
        find.text('Reminders are scheduled on your device, so they work offline.'),
        findsOneWidget,
      );
    });

    testWidgets('DeleteAccountScreen renders 1:1 Figma danger layout, bullets, and confirmation input', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier(const AuthState(
                  isAuthenticated: true,
                  userId: 'test-user',
                  hasPassword: true,
                ))),
          ],
          child: const MaterialApp(
            home: DeleteAccountScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Delete everything?'), findsOneWidget);
      expect(find.text('This permanently deletes:'), findsOneWidget);
      expect(find.text('Back up first'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Delete account and data'), findsOneWidget);
    });
  });
}
