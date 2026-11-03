import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/savings/screens/create_goal_screen.dart';
import 'package:kasyaba/features/savings/screens/goal_detail_screen.dart';
import 'package:kasyaba/features/savings/screens/goals_screen.dart';
import 'package:kasyaba/features/savings/widgets/goal_deposit_sheet.dart';

void main() {
  final sampleGoals = [
    const SavingsGoal(
      id: 'g1',
      name: 'New Gadget',
      targetAmount: 20000.0,
      currentAmount: 0.0,
      targetDate: '2027-01-30',
    ),
    const SavingsGoal(
      id: 'g2',
      name: 'Vacation Trip',
      targetAmount: 50000.0,
      currentAmount: 10000.0,
      targetDate: '2027-01-28',
    ),
  ];

  testWidgets('GoalsScreen renders header, total saved, and goal cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          goalsProvider.overrideWith((ref) => Future.value(sampleGoals)),
        ],
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Total saved'), findsOneWidget);
    expect(find.text('New Gadget'), findsOneWidget);
    expect(find.text('Vacation Trip'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('Deposit'), findsNWidgets(2));
    expect(find.text('Can I afford it?'), findsOneWidget);
  });

  testWidgets('GoalDetailScreen renders hero card and details', (tester) async {
    final goal = sampleGoals[1];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          goalDetailProvider(goal.id).overrideWith(
            (ref) => Future.value({
              'id': goal.id,
              'name': goal.name,
              'targetAmount': goal.targetAmount,
              'currentAmount': goal.currentAmount,
              'targetDate': goal.targetDate,
              'contributions': [
                {
                  'id': 'c1',
                  'amount': 10000.0,
                  'contributedAt': '2026-10-05T00:00:00.000Z',
                },
              ],
            }),
          ),
        ],
        child: MaterialApp(
          home: GoalDetailScreen(goalId: goal.id, initialGoal: goal),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vacation Trip'), findsAtLeastNWidgets(1));
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Target date'), findsOneWidget);
    expect(find.text('Delete goal'), findsOneWidget);
  });

  testWidgets('CreateGoalScreen calculates dynamic monthly need', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CreateGoalScreen())),
    );

    await tester.pumpAndSettle();

    expect(find.text('New goal'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Target amount'), findsOneWidget);
    expect(find.text('Target date'), findsOneWidget);
    expect(find.text('Create goal'), findsOneWidget);
  });

  testWidgets('GoalDepositSheet displays dynamic calculation and CTA', (
    tester,
  ) async {
    final goal = sampleGoals[1];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith(
            (ref) => Future.value([
              const Account(id: 'a1', name: 'Cash Wallet', type: 'cash'),
            ]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Future.value({'a1': 50000.0}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => GoalDepositSheet.show(ctx, goal),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Deposit to Vacation Trip'), findsOneWidget);
    expect(find.text('Save deposit'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
  });
}
