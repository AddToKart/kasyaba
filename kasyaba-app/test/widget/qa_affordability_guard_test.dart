// Regression coverage for the affordability sheet:
//  * live-data failure is visible and blocks evaluation
//  * no fabricated work-hours math (₱255.68/hr, ₱45,000 salary) when the
//    profile has no salary

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/dashboard/widgets/kasyaba_affordability_sheet.dart';

import 'support/qa_harness.dart';

void main() {
  Future<QaHarness> openAffordabilitySheet(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      QaSheetLauncher(
        label: 'Open affordability',
        onLaunch: (context) => showKasyaBaAffordabilitySheet(context),
      ),
      overrides: overrides,
    );

    await tester.tap(find.text('Open affordability'));
    await tester.pumpAndSettle();
    expect(find.text('Evaluate affordability'), findsWidgets);
    return harness;
  }

  testWidgets(
    'dashboard error shows the live-data warning and disables Evaluate',
    (tester) async {
      await openAffordabilitySheet(
        tester,
        overrides: <Override>[
          dashboardProvider.overrideWith(
            (ref) async => throw StateError('qa dashboard offline'),
          ),
          accountBalancesProvider.overrideWith(
            (ref) async => const <String, double>{},
          ),
          billsProvider.overrideWith((ref) async => const <BillItem>[]),
          goalsProvider.overrideWith((ref) async => const <SavingsGoal>[]),
          userProfileProvider.overrideWith(
            (ref) async => qaDefaultProfile(),
          ),
        ],
      );

      expect(
        find.text('Live account data is unavailable. Reconnect and try again.'),
        findsOneWidget,
      );

      final evaluate = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Evaluate affordability'),
      );
      expect(
        evaluate.onPressed,
        isNull,
        reason: 'Evaluate must stay disabled while live account data failed.',
      );
    },
  );

  testWidgets(
    'no work-hours numbers are fabricated when userProfile.salaryAmount is null',
    (tester) async {
      await openAffordabilitySheet(
        tester,
        overrides: <Override>[
          dashboardProvider.overrideWith((ref) async => qaDefaultDashboard),
          accountBalancesProvider.overrideWith(
            (ref) async => const <String, double>{qaAccountId: 25000},
          ),
          billsProvider.overrideWith((ref) async => const <BillItem>[]),
          goalsProvider.overrideWith((ref) async => const <SavingsGoal>[]),
          userProfileProvider.overrideWith(
            (ref) async => qaDefaultProfile(),
          ),
        ],
      );

      // Salary is null; confirm the fixture never accidentally supplies one.
      expect(find.textContaining('45,000'), findsNothing);

      final priceField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == '50,000',
      );
      expect(priceField, findsOneWidget);
      await tester.enterText(priceField, '25000');
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Evaluate affordability'),
      );
      await tester.pumpAndSettle();

      // The evaluation result is on screen, so the assertion below is about
      // the actual rendered result card, not an empty state.
      expect(find.text('Safely affordable'), findsOneWidget);

      expect(find.textContaining('work hours ·'), findsNothing);
      expect(find.textContaining('255.68'), findsNothing);
      expect(find.textContaining('45,000'), findsNothing);
      expect(find.textContaining('45000'), findsNothing);
    },
  );
}
