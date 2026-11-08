import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/utils/deterministic_math.dart';
import 'package:kasyaba/features/planning/screens/math_breakdown_screen.dart';

void main() {
  testWidgets('MathBreakdownScreen renders 1:1 "How we calculate" page matching design',
      (tester) async {
    final mockCalculation = DailySafeSpendCalculation(
      totalLiquidBalance: 825149.80,
      unpaidBillsDue: 0.0,
      unpaidBillsCount: 0,
      scheduledGoalContributions: 22511.78,
      activeGoalsCount: 3,
      goalDetails: const [
        GoalContributionDetail(
          title: 'New Gadget',
          targetAmount: 50000.0,
          currentAmount: 10000.0,
          remainingAmount: 40000.0,
          dailyRate: 500.0,
          daysCounted: 11,
          totalContribution: 5500.0,
        ),
        GoalContributionDetail(
          title: 'Vacation Trip',
          targetAmount: 80000.0,
          currentAmount: 20000.0,
          remainingAmount: 60000.0,
          dailyRate: 800.0,
          daysCounted: 11,
          totalContribution: 8800.0,
        ),
        GoalContributionDetail(
          title: 'Emergency Fund',
          targetAmount: 100000.0,
          currentAmount: 30000.0,
          remainingAmount: 70000.0,
          dailyRate: 746.52,
          daysCounted: 11,
          totalContribution: 8211.78,
        ),
      ],
      daysUntilPayday: 11,
      nextPayday: DateTime(2026, 10, 30),
      numerator: 802638.03,
      dailySafeSpend: 72967.09,
      paydaySchedule: '15th & 30th',
      paydayFrequency: 'Semi-monthly',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MathBreakdownScreen(calculation: mockCalculation),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Header & Title
    expect(find.text('How we calculate'), findsOneWidget);

    // 2. Card 1: Exact deterministic formula
    expect(find.text('Exact deterministic formula'), findsOneWidget);
    expect(find.text('Σ'), findsOneWidget);
    expect(find.textContaining('Daily Safe Spend = Math.max(0,'), findsOneWidget);
    expect(find.textContaining('(Available Cash Pool) ÷ (Days Left Until Payday)'),
        findsOneWidget);

    // 3. Card 2: Find your safe cash
    expect(find.text('Find your safe cash'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Cash in wallets'), findsOneWidget);
    expect(find.text('Unpaid bills before payday'), findsOneWidget);
    expect(find.text('Savings for 3 goals'), findsOneWidget);
    expect(find.text('New Gadget, Vacation Trip, Emergency Fund'), findsOneWidget);
    expect(find.text('Safe cash'), findsOneWidget);

    // 4. Card 3: Spread it until payday
    expect(find.text('Spread it until payday'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Next configured payday'), findsOneWidget);
    expect(find.text('Schedule: 15th & 30th'), findsOneWidget);
    expect(find.text('October 30, 2026'), findsOneWidget);
    expect(find.text('Days until payday'), findsOneWidget);
    expect(find.text('÷ 11 days'), findsOneWidget);

    // 5. Card 4: Daily Safe Spend Final Result
    expect(find.text('DAILY SAFE SPEND'), findsOneWidget);
    expect(find.text('Available to spend today'), findsOneWidget);
    expect(find.textContaining('/ day'), findsOneWidget);
  });
}
