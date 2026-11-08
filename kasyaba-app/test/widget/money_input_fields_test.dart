// Regression armor for the zero-width money input bug.
//
// An empty TextField wrapped in IntrinsicWidth collapses to 0px and becomes
// untappable on a real device (only the static currency glyph is visible).
// enterText() alone cannot catch that, so every money hero field is asserted:
//  1) rendered width >= 96 px while empty,
//  2) tapping it focuses the field,
//  3) typed digits reach the controller.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/bills/screens/add_bill_screen.dart';
import 'package:kasyaba/features/savings/screens/create_goal_screen.dart';
import 'package:kasyaba/features/savings/widgets/goal_deposit_sheet.dart';
import 'package:kasyaba/features/transactions/screens/add_transaction_screen.dart';

import 'support/qa_harness.dart';

const _goal = SavingsGoal(
  id: 'goal-input-qa',
  name: 'QA Goal',
  targetAmount: 50000,
  currentAmount: 0,
);

Finder _moneyField(double fontSize) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.style?.fontSize == fontSize,
  );
}

Future<void> _expectTypable(
  WidgetTester tester,
  double fontSize, {
  required String typed,
}) async {
  final field = _moneyField(fontSize);
  expect(
    field,
    findsOneWidget,
    reason: 'money hero field with fontSize $fontSize should exist exactly once',
  );

  final size = tester.getSize(field);
  expect(
    size.width,
    greaterThanOrEqualTo(96),
    reason: 'empty money field must not collapse below tap-target width',
  );

  await tester.tap(field);
  await tester.pump();

  final editable = tester.widget<EditableText>(
    find.byWidgetPredicate(
      (widget) => widget is EditableText && widget.style.fontSize == fontSize,
    ),
  );
  expect(
    editable.focusNode.hasFocus,
    isTrue,
    reason: 'tapping the money field must acquire focus (keyboard opens)',
  );

  await tester.enterText(field, typed);
  await tester.pump();

  final state = tester.widget<TextField>(field);
  expect(state.controller?.text, typed);
}

void main() {
  final harness = QaHarness();

  testWidgets('goal target amount is tappable and typable when empty',
      (tester) async {
    await harness.pumpScreen(
      tester,
      const CreateGoalScreen(),
      overrides: qaDefaultDataOverrides(),
    );

    await _expectTypable(tester, 40, typed: '30000');
  });

  testWidgets('goal deposit amount is tappable and typable when empty',
      (tester) async {
    final hostKey = GlobalKey();
    await harness.pumpScreen(
      tester,
      SizedBox(key: hostKey),
      overrides: qaDefaultDataOverrides(),
    );

    showGoalDepositSheet(hostKey.currentContext!, _goal);
    await tester.pumpAndSettle();

    await _expectTypable(tester, 44, typed: '5000');
  });

  testWidgets('transaction amount hero is tappable and typable when empty',
      (tester) async {
    await harness.pumpScreen(
      tester,
      const AddTransactionScreen(),
      overrides: qaDefaultDataOverrides(),
    );

    await _expectTypable(tester, 46, typed: '250');
  });

  testWidgets('bill amount is tappable and typable when empty',
      (tester) async {
    await harness.pumpScreen(
      tester,
      const AddBillScreen(),
      overrides: qaDefaultDataOverrides(),
    );

    await _expectTypable(tester, 44, typed: '999.75');
  });
}
