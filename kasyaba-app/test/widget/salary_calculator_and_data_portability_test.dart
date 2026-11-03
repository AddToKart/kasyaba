import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/settings/screens/settings_screen.dart';
import 'package:kasyaba/features/settings/screens/backup_export_screen.dart';
import 'package:kasyaba/features/settings/widgets/data_backup_sheets.dart';

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const testProfile = UserProfile(
    id: 'user-1111-1111-1111-1111-111111111111',
    email: 'kurt@kasyaba.ph',
    displayName: 'Kurt C.',
    salaryAmount: 50000.0,
    paydayFrequency: 'semi-monthly',
    paydaySchedule: '15th & 30th',
    minimumBalanceThreshold: 2000.0,
  );

  group('SettingsScreen - 1:1 Figma Profile & Data Portability', () {
    testWidgets(
      'renders Profile screen with 1:1 Figma layout, Salary Card, and Groups',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProfileProvider.overrideWith((ref) async => testProfile),
              budgetStatusProvider.overrideWith(
                (ref) async => BudgetStatus.empty(),
              ),
              authProvider.overrideWith(
                (ref) => FakeAuthNotifier(
                  const AuthState(
                    isAuthenticated: true,
                    userId: 'user-1111-1111-1111-1111-111111111111',
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

        // Verify Header & Hero
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Kurt C.'), findsOneWidget);
        expect(find.text('kurt@kasyaba.ph'), findsOneWidget);

        // Verify Salary summary card shows configured monthly net pay and semi-monthly payout
        expect(find.text('Salary and payday'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('₱50,000.00 '), findsOneWidget);
        expect(find.text('per month'), findsOneWidget);
        expect(
          find.text('Paid on the 15th & 30th · ₱25,000.00 each'),
          findsOneWidget,
        );

        // Verify MONEY and YOUR DATA groups
        expect(find.text('MONEY'), findsOneWidget);
        expect(find.text('Accounts and wallets'), findsOneWidget);
        expect(find.text('Budgets'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);

        expect(find.text('YOUR DATA'), findsOneWidget);
        expect(find.text('Backup and export'), findsOneWidget);
        expect(find.text('Privacy policy'), findsOneWidget);
        expect(find.text('About Kasyaba'), findsOneWidget);

        expect(find.text('Sign out'), findsOneWidget);
        expect(find.text('Delete account and data'), findsOneWidget);
      },
    );

    testWidgets('renders BackupExportScreen with 1:1 Figma layout and CTAs', (
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
              (ref) async => BudgetStatus.empty(),
            ),
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(
                const AuthState(
                  isAuthenticated: true,
                  userId: 'user-1111-1111-1111-1111-111111111111',
                  email: 'kurt@kasyaba.ph',
                  displayName: 'Kurt C.',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: BackupExportScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Backup and export'), findsOneWidget);
      expect(find.text('Last backup'), findsOneWidget);
      expect(find.text('Never'), findsOneWidget);
      expect(find.text('Back up'), findsOneWidget);
      expect(find.text('Create backup'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Choose file'), findsOneWidget);
      expect(find.text('Export to CSV'), findsOneWidget);
      expect(find.text('Export transactions'), findsOneWidget);
    });

    testWidgets(
      'opens Salary Settings modal and toggles PH Statutory Calculator with live payslip breakdown',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProfileProvider.overrideWith((ref) async => testProfile),
              budgetStatusProvider.overrideWith(
                (ref) async => BudgetStatus.empty(),
              ),
              authProvider.overrideWith(
                (ref) => FakeAuthNotifier(
                  const AuthState(
                    isAuthenticated: true,
                    userId: 'user-1111-1111-1111-1111-111111111111',
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

        // Tap on Edit button in Salary card
        await tester.tap(find.byTooltip('Edit salary & payday settings'));
        await tester.pumpAndSettle();

        // Modal bottom sheet should be visible
        expect(find.text('Salary & Payday Settings'), findsOneWidget);
        expect(find.text('Direct Net Pay'), findsOneWidget);
        expect(find.text('PH Statutory Calc'), findsOneWidget);
        expect(find.text('Monthly Net Take-Home Salary'), findsOneWidget);

        // Tap on "PH Statutory Calc" mode
        await tester.tap(find.text('PH Statutory Calc'));
        await tester.pumpAndSettle();

        // Verify inputs switched
        expect(find.text('Monthly Gross Basic Salary'), findsOneWidget);
        expect(find.text('Non-Taxable Allowances'), findsOneWidget);

        // Enter 30000 gross
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, '30000');
        await tester.pumpAndSettle();

        // Verify computed net pay is displayed
        expect(find.text('ESTIMATED NET PAYSLIP (PH 2026)'), findsOneWidget);
        expect(find.text('Computed Net Pay:'), findsOneWidget);
        expect(find.text('₱26,670.00'), findsOneWidget);
      },
    );

    testWidgets('RestoreBackupSheet validates JSON schema live', (
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
              (ref) async => BudgetStatus.empty(),
            ),
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(
                const AuthState(
                  isAuthenticated: true,
                  userId: 'user-1111-1111-1111-1111-111111111111',
                  email: 'kurt@kasyaba.ph',
                  displayName: 'Kurt C.',
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showRestoreBackupSheet(context, ref),
                  child: const Text('Open Restore'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Restore sheet
      await tester.tap(find.text('Open Restore'));
      await tester.pumpAndSettle();

      expect(find.text('Import Backup'), findsOneWidget);
      expect(find.text('SCHEMA VALIDATED'), findsOneWidget);

      // Type invalid JSON
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, '{ invalid json');
      await tester.pumpAndSettle();

      expect(find.textContaining('Invalid JSON format:'), findsOneWidget);

      // Type valid JSON missing required fields
      await tester.enterText(inputField, '{"some": "data"}');
      await tester.pumpAndSettle();

      expect(find.textContaining('Unrecognized backup schema'), findsOneWidget);

      // Type valid full backup JSON
      await tester.enterText(inputField, '''
      {
        "exportedAt": "2026-10-17T00:00:00.000Z",
        "user": {"email": "kurt@kasyaba.ph"},
        "accounts": [{"id": "acc-1", "name": "BDO"}],
        "expenses": [{"id": "exp-1", "amount": 100.0}]
      }
      ''');
      await tester.pumpAndSettle();

      expect(find.text('Valid Backup Detected (2 records)'), findsOneWidget);
      expect(find.text('Restore & Sync Backup'), findsOneWidget);
    });
  });
}
