// Regression coverage for the goal-deposit sheet guard:
//  * no fabricated ₱825,149.80 balance
//  * submit disabled when there are no wallets
//  * real account balance + empty amount prefill when wallets exist

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/savings/widgets/goal_deposit_sheet.dart';
import 'package:kasyaba/shared/widgets/pill_button.dart';

import 'support/qa_harness.dart';

void main() {
  const goal = SavingsGoal(
    id: 'goal-qa-1',
    name: 'QA Emergency Fund',
    targetAmount: 50000,
    currentAmount: 10000,
  );

  Future<QaHarness> openDepositSheet(
    WidgetTester tester, {
    required List<Account> accounts,
    required Map<String, double> balances,
  }) async {
    final harness = QaHarness();
    await harness.pumpScreen(
      tester,
      QaSheetLauncher(
        label: 'Open deposit',
        onLaunch: (context) => showGoalDepositSheet(context, goal),
      ),
      overrides: <Override>[
        accountsProvider.overrideWith((ref) async => accounts),
        accountBalancesProvider.overrideWith((ref) async => balances),
      ],
    );

    await tester.tap(find.text('Open deposit'));
    await tester.pumpAndSettle();

    expect(find.text('Deposit to QA Emergency Fund'), findsOneWidget);
    return harness;
  }

  testWidgets(
    'no wallets: CTA disabled, friendly message, and no fake 825149.80 balance',
    (tester) async {
      await openDepositSheet(
        tester,
        accounts: const <Account>[],
        balances: const <String, double>{},
      );

      expect(find.text('No wallets available yet'), findsOneWidget);

      final cta = tester.widget<PillButton>(
        find.widgetWithText(PillButton, 'Save deposit'),
      );
      expect(
        cta.onPressed,
        isNull,
        reason: 'Deposit CTA must be disabled when no wallets are loaded.',
      );

      expect(find.textContaining('825,149'), findsNothing);
      expect(find.textContaining('825149.80'), findsNothing);
    },
  );

  testWidgets(
    'wallets available: real balance is shown and the amount field starts empty',
    (tester) async {
      await openDepositSheet(
        tester,
        accounts: const <Account>[
          Account(id: 'wallet-qa-1', name: 'QA Wallet', type: 'cash'),
        ],
        balances: const <String, double>{'wallet-qa-1': 9876.54},
      );

      expect(find.text('QA Wallet'), findsOneWidget);
      expect(find.text('₱9,876.54'), findsOneWidget);

      final amountField = tester.widget<TextField>(find.byType(TextField));
      expect(
        amountField.controller?.text ?? '',
        isEmpty,
        reason: 'Deposit amount must never be prefilled with a mock value.',
      );
      expect(find.text('5000'), findsNothing);
      expect(find.text('5,000'), findsNothing);

      final cta = tester.widget<PillButton>(
        find.widgetWithText(PillButton, 'Save deposit'),
      );
      expect(
        cta.onPressed,
        isNotNull,
        reason: 'Deposit CTA must be enabled once a wallet is available.',
      );
    },
  );
}
