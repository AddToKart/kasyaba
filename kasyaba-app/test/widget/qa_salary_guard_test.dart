// Regression coverage for the salary-save guard:
// saving must never PATCH `/auth/me` with `salaryAmount: '0.00'`.
//
// This reproduces the fixed blocker where the PH statutory calculator mode
// accepted empty gross/allowance fields and persisted a zero net salary.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/settings/screens/settings_screen.dart';
import 'package:kasyaba/shared/widgets/app_sheet.dart';

import 'support/qa_harness.dart';

void main() {
  UserProfile profileWithoutSalary() {
    return const UserProfile(
      id: qaTestUserId,
      email: qaTestEmail,
      displayName: 'QA User',
      paydayFrequency: 'semi-monthly',
      paydaySchedule: '15th & 30th',
    );
  }

  Future<QaHarness> openSalarySheet(WidgetTester tester) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      const SettingsScreen(),
      overrides: <Override>[
        userProfileProvider.overrideWith((ref) async => profileWithoutSalary()),
        budgetStatusProvider.overrideWith(
          (ref) async => BudgetStatus.empty(),
        ),
      ],
      viewport: const Size(800, 1600),
    );

    await tester.tap(find.text('Set salary'));
    await tester.pumpAndSettle();

    expect(find.text('Salary & Payday Settings'), findsOneWidget);
    expect(find.text('Direct Net Pay'), findsOneWidget);
    expect(find.text('PH Statutory Calc'), findsOneWidget);
    return harness;
  }

  testWidgets(
    'PH Statutory Calc with empty gross/allowance does not PATCH and keeps the sheet open',
    (tester) async {
      final harness = await openSalarySheet(tester);

      await tester.tap(find.text('PH Statutory Calc'));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Gross Basic Salary'), findsOneWidget);
      expect(find.text('Non-Taxable Allowances'), findsOneWidget);

      // Both calculator inputs must start empty (no prefilled salary leaks
      // across modes).
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields, hasLength(2));
      for (final field in fields) {
        expect(field.controller?.text ?? '', isEmpty);
      }

      await tester.ensureVisible(find.text('Save settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();

      expect(
        harness.adapter.calls('PATCH', '/auth/me'),
        isEmpty,
        reason: 'Saving with empty gross salary must never reach the API.',
      );
      expect(
        find.byType(AppSheet),
        findsOneWidget,
        reason: 'Validation failure must keep the salary sheet open.',
      );
      expect(
        find.textContaining('gross'),
        findsWidgets,
        reason: 'A visible error must explain that gross salary is required.',
      );
    },
  );

  testWidgets(
    'Direct Net Pay with empty salary does not PATCH and shows the net-salary error',
    (tester) async {
      final harness = await openSalarySheet(tester);

      final salaryField =
          tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(salaryField.controller?.text ?? '', isEmpty);

      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();

      expect(
        harness.adapter.calls('PATCH', '/auth/me'),
        isEmpty,
        reason: 'Saving an empty direct net salary must never reach the API.',
      );
      expect(find.byType(AppSheet), findsOneWidget);
      expect(
        find.textContaining('Enter your monthly net salary'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'PH Statutory Calc with gross 30000 sends exactly one positive salaryAmount',
    (tester) async {
      final harness = await openSalarySheet(tester);

      await tester.tap(find.text('PH Statutory Calc'));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Gross Basic Salary'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '30000');
      await tester.pumpAndSettle();

      // The live payslip proves the calculator path is active.
      expect(find.text('₱26,670.00'), findsOneWidget);
      expect(find.text('ESTIMATED NET PAYSLIP (PH 2026)'), findsOneWidget);

      await tester.ensureVisible(find.text('Save settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final patches = harness.adapter.calls('PATCH', '/auth/me');
      expect(
        patches,
        hasLength(1),
        reason: 'A valid calculator save must PATCH /auth/me exactly once.',
      );

      final body = patches.single.jsonBody;
      expect(body, isNotNull);
      final salaryAmount = body!['salaryAmount'];
      expect(salaryAmount, isA<String>());
      expect(salaryAmount, isNot('0.00'));
      expect(double.parse(salaryAmount! as String), greaterThan(0));

      // The save succeeded, so the modal is dismissed.
      expect(find.text('Salary & Payday Settings'), findsNothing);
    },
  );
}
