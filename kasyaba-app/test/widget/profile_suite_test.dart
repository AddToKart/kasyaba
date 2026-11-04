import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/notifications/notification_preferences.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/providers/preference_providers.dart';
import 'package:kasyaba/core/storage/secure_storage_service.dart';
import 'package:kasyaba/features/accounts/screens/accounts_screen.dart';
import 'package:kasyaba/features/settings/screens/notification_settings_screen.dart';
import 'package:kasyaba/features/settings/screens/delete_account_screen.dart';
import 'package:kasyaba/features/settings/screens/privacy_about_screen.dart';
import 'package:kasyaba/shared/widgets/figma_toggle_switch.dart';

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSecureStorage extends SecureStorageService {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> readRaw(String key) async => values[key];

  @override
  Future<void> writeRaw(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  final testAccounts = [
    const Account(id: 'acc-1', name: 'Cash Wallet', type: 'cash'),
    const Account(id: 'acc-2', name: 'GCash', type: 'ewallet'),
  ];

  group('1:1 Figma Profile Suite Tests', () {
    testWidgets(
      'AccountsScreen renders 1:1 Figma layout, balance hero, and Safe-to-Spend toggles',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              accountsProvider.overrideWith((ref) async => testAccounts),
              accountBalancesProvider.overrideWith(
                (ref) async => {'acc-1': 825149.80, 'acc-2': 0.0},
              ),
            ],
            child: const MaterialApp(home: AccountsScreen()),
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
      },
    );

    testWidgets(
      'NotificationSettingsScreen renders persisted notification groups and time picker',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProfileProvider.overrideWith(
                (ref) async => const UserProfile(
                  id: 'user-profile-test',
                  email: 'kurt@kasyaba.ph',
                  displayName: 'Kurt C.',
                  salaryAmount: 50000.0,
                  paydayFrequency: 'semi-monthly',
                  paydaySchedule: '15th & 30th',
                ),
              ),
            ],
            child: const MaterialApp(home: NotificationSettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Header
        expect(find.text('Notifications'), findsOneWidget);

        // Group 1
        expect(find.text('Bill reminders'), findsOneWidget);
        expect(find.text('Before each bill is due'), findsOneWidget);
        expect(find.text('Remind me '), findsOneWidget);
        expect(find.text('1 day before'), findsOneWidget);
        expect(find.text('Budget alerts'), findsOneWidget);
        expect(find.text('At 80% and when you go over'), findsOneWidget);
        expect(find.text('Payday reminder'), findsOneWidget);
        expect(find.text('On the 15th & 30th'), findsOneWidget);

        // Group 2
        expect(find.text('Goal milestones'), findsOneWidget);
        expect(find.text('When a goal reaches 25%, 50%, 75%'), findsOneWidget);
        expect(find.text('Weekly summary'), findsOneWidget);
        expect(find.text('Every Sunday evening'), findsOneWidget);

        // Time picker row & footnote
        expect(find.text('Time'), findsOneWidget);
        expect(find.text('9:00 AM'), findsOneWidget);
        expect(
          find.text(
            'Reminders are scheduled on your device, so they work offline.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'DeleteAccountScreen renders 1:1 Figma danger layout, bullets, and confirmation input',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => FakeAuthNotifier(
                  const AuthState(
                    isAuthenticated: true,
                    userId: 'test-user',
                    hasPassword: true,
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: DeleteAccountScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Delete everything?'), findsOneWidget);
        expect(find.text('This permanently deletes:'), findsOneWidget);
        expect(find.text('Back up first'), findsOneWidget);
        expect(find.text('Type'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Delete account and data'), findsOneWidget);
      },
    );
  });

  group('Persisted profile controls', () {
    testWidgets('safe-to-spend toggle persists account exclusions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _FakeSecureStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(storage),
            accountsProvider.overrideWith((ref) async => testAccounts),
            accountBalancesProvider.overrideWith(
              (ref) async => {'acc-1': 1000.0, 'acc-2': 0.0},
            ),
          ],
          child: const MaterialApp(home: AccountsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(FigmaToggleSwitch).first);
      await tester.pumpAndSettle();

      expect(storage.values[ExcludedAccountsNotifier.storageKey], '["acc-1"]');
    });

    testWidgets('notification controls persist preference changes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _FakeSecureStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(storage),
            userProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: 'user-notification-test',
                email: 'kurt@kasyaba.ph',
                displayName: 'Kurt C.',
                paydayFrequency: 'semi-monthly',
                paydaySchedule: '15th & 30th',
              ),
            ),
          ],
          child: const MaterialApp(home: NotificationSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('1 day before'));
      await tester.pumpAndSettle();
      expect(
        storage.values[NotificationPreferencesNotifier.remindDaysBeforeKey],
        '2',
      );

      await tester.tap(find.byType(FigmaToggleSwitch).first);
      await tester.pumpAndSettle();
      expect(
        storage.values[NotificationPreferencesNotifier.billRemindersKey],
        'false',
      );

      await tester.tap(find.byType(FigmaToggleSwitch).at(1));
      await tester.pumpAndSettle();
      expect(
        storage.values[NotificationPreferencesNotifier.budgetAlertsKey],
        'false',
      );

      await tester.tap(find.byType(FigmaToggleSwitch).at(2));
      await tester.pumpAndSettle();
      expect(
        storage.values[NotificationPreferencesNotifier.paydayReminderKey],
        'false',
      );

      await tester.tap(find.byType(FigmaToggleSwitch).at(3));
      await tester.pumpAndSettle();
      expect(
        storage.values[NotificationPreferencesNotifier.goalMilestonesKey],
        'false',
      );

      await tester.tap(find.byType(FigmaToggleSwitch).at(4));
      await tester.pumpAndSettle();
      expect(
        storage.values[NotificationPreferencesNotifier.weeklySummaryKey],
        'true',
      );
    });

    testWidgets('PrivacyAndAboutScreen renders 1:1 Figma layout and modal sheets', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: PrivacyAndAboutScreen()),
      );

      await tester.pumpAndSettle();

      // Verify Header & Hero Card
      expect(find.text('Privacy and about'), findsOneWidget);
      expect(find.text('Your numbers stay yours'), findsOneWidget);
      expect(
        find.text(
          'Every calculation runs on your device. Your data is never shared with third-party advertisers, trackers, or commercial AI models.',
        ),
        findsOneWidget,
      );

      // Verify "What we keep" section
      expect(find.text('What we keep'), findsOneWidget);
      expect(find.text('Your records'), findsOneWidget);
      expect(find.text('Local-first & private sync'), findsOneWidget);
      expect(find.text('Calculations'), findsOneWidget);
      expect(find.text('100% on-device math'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('None (100% deterministic)'), findsOneWidget);

      // Verify "About" section
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('0.1.0 (Build 1)'), findsOneWidget);
      expect(find.text('Terms of service'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('Read'), findsNWidgets(2));

      // Tap "Terms of service" -> sheet opens
      await tester.tap(find.text('Terms of service'));
      await tester.pumpAndSettle();
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap "Privacy policy" -> sheet opens
      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });
}
