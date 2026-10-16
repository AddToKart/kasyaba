import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/settings/screens/settings_screen.dart';
import 'package:kasyaba/features/settings/widgets/data_backup_sheets.dart';
import 'package:kasyaba/shared/widgets/modern_text_field.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
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

  group('SettingsScreen - Localization & Data Portability', () {
    testWidgets('renders Salary Card and Data & Backup Management section', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) async => testProfile),
            authProvider.overrideWith((ref) => FakeAuthNotifier(const AuthState(
                  isAuthenticated: true,
                  userId: 'user-1111-1111-1111-1111-111111111111',
                  email: 'kurt@kasyaba.ph',
                  displayName: 'Kurt C.',
                ))),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Salary summary card shows configured monthly net pay and semi-monthly payout
      expect(find.text('Salary & Payday Settings'), findsOneWidget);
      expect(find.text('Monthly Net Pay:'), findsOneWidget);
      expect(find.text('₱50,000.00 / month'), findsOneWidget);
      expect(find.text('Estimated Semi-Monthly:'), findsOneWidget);
      expect(find.text('₱25,000.00 / payout'), findsOneWidget);

      // Verify DATA & BACKUP MANAGEMENT group
      expect(find.text('DATA & BACKUP MANAGEMENT'), findsOneWidget);
      expect(find.text('Export Backup (JSON)'), findsOneWidget);
      expect(find.text('Import / Restore Backup (JSON)'), findsOneWidget);
      expect(find.text('Export Transactions to CSV'), findsOneWidget);
    });

    testWidgets('opens Salary Settings modal and toggles PH Statutory Calculator with live payslip breakdown', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) async => testProfile),
            authProvider.overrideWith((ref) => FakeAuthNotifier(const AuthState(
                  isAuthenticated: true,
                  userId: 'user-1111-1111-1111-1111-111111111111',
                  email: 'kurt@kasyaba.ph',
                  displayName: 'Kurt C.',
                ))),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Edit button in Salary card
      await tester.tap(find.byTooltip('Edit salary & payday settings'));
      await tester.pumpAndSettle();

      // Modal bottom sheet should be visible
      expect(find.text('Direct Net Pay'), findsOneWidget);
      expect(find.text('PH Statutory Calc'), findsOneWidget);

      // Initially in Direct Net Pay mode
      expect(find.text('Monthly Net Take-Home Salary (₱)'), findsOneWidget);

      // Tap on "PH Statutory Calc" mode
      await tester.tap(find.text('PH Statutory Calc'));
      await tester.pumpAndSettle();

      // Verify inputs switched
      expect(find.text('Monthly Gross Basic Salary (₱)'), findsOneWidget);
      expect(find.text('Non-Taxable Allowances / De Minimis (₱)'), findsOneWidget);

      // Find Gross Basic Salary input
      final grossInput = find.descendant(
        of: find.widgetWithText(ModernTextField, 'Monthly Gross Basic Salary (₱)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(grossInput, '30000');
      await tester.pumpAndSettle();

      // Verify live statutory payslip breakdown is rendered
      expect(find.text('PHILIPPINE PAYSLIP BREAKDOWN'), findsOneWidget);
      expect(find.text('STATUTORY 2026'), findsOneWidget);
      expect(find.text('Gross Basic Salary'), findsOneWidget);
      expect(find.text('SSS Employee (RA 11199)'), findsOneWidget);
      expect(find.text('PhilHealth (2.5% share)'), findsOneWidget);
      expect(find.text('Pag-IBIG Fund (Standard)'), findsOneWidget);
      expect(find.text('TRAIN Withholding Tax'), findsOneWidget);
      expect(find.text('Total Monthly Deductions'), findsOneWidget);

      // Net Monthly Take-Home should be ₱26,670.00
      expect(find.text('Net Monthly Take-Home'), findsOneWidget);
      expect(find.text('₱26,670.00'), findsOneWidget);
      expect(find.text('₱13,335.00 / payout'), findsOneWidget);

      // Add 2000 allowances
      final allowInput = find.descendant(
        of: find.widgetWithText(ModernTextField, 'Non-Taxable Allowances / De Minimis (₱)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(allowInput, '2000');
      await tester.pumpAndSettle();

      expect(find.text('+ Non-Taxable Allowances'), findsOneWidget);
      // Net should increase by 2000 => ₱28,670.00
      expect(find.text('₱28,670.00'), findsOneWidget);
      expect(find.text('₱14,335.00 / payout'), findsOneWidget);
    });

    testWidgets('RestoreBackupSheet validates JSON schema live', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) async => testProfile),
            authProvider.overrideWith((ref) => FakeAuthNotifier(const AuthState(
                  isAuthenticated: true,
                  userId: 'user-1111-1111-1111-1111-111111111111',
                  email: 'kurt@kasyaba.ph',
                  displayName: 'Kurt C.',
                ))),
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
