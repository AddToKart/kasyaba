// Regression armor for the goal-deposit wallet picker.
// Previously the "From" row was a static card locked to the first wallet, so
// deposits could only ever come from one wallet. The row is now a tappable
// picker over the whole wallet list.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/savings/widgets/goal_deposit_sheet.dart';

import 'support/qa_harness.dart';

void main() {
  const goal = SavingsGoal(
    id: 'goal-picker-qa',
    name: 'QA Goal',
    targetAmount: 5000,
    currentAmount: 0,
  );

  testWidgets('deposit sheet wallet row opens the picker and switching wallets updates the From card', (tester) async {
    final harness = QaHarness();
    final hostKey = GlobalKey();
    await harness.pumpScreen(
      tester,
      SizedBox(key: hostKey),
      overrides: qaDefaultDataOverrides(),
    );

    showGoalDepositSheet(hostKey.currentContext!, goal);
    await tester.pumpAndSettle();

    // Default from-wallet is the first one (Cash Wallet per the fixture).
    expect(find.text('Cash Wallet'), findsOneWidget);

    // Tap the From card to open the wallet picker.
    await tester.tap(find.text('Cash Wallet'));
    await tester.pumpAndSettle();

    // The picker should list both fixture wallets.
    expect(find.text('GCash'), findsOneWidget);

    // Choose GCash.
    await tester.tap(find.text('GCash'));
    await tester.pumpAndSettle();

    // The From card now shows GCash.
    expect(find.text('GCash'), findsOneWidget);
    expect(find.text('Cash Wallet'), findsNothing);
  });
}
