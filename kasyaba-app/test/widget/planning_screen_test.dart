import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/planning/screens/planning_screen.dart';

void main() {
  final mockOverview = PlanningOverview(
    from: DateTime(2026, 10, 16),
    to: DateTime(2026, 11, 15),
    currentBalance: 825149.80,
    minimumBalanceThreshold: 0.0,
    totalPlannedIncome: 0.0,
    totalPlannedExpenses: 4799.0,
    totalUpcomingBills: 6300.0,
    projectedClosingBalance: 814050.80,
    availableBuffer: 814050.80,
    safeToSpendPerDay: 72967.09,
    daysInWindow: 31,
    status: 'clear',
    calculationNote: 'Planning window is 31 days.',
    days: [
      PlanningDay(
        date: DateTime(2026, 10, 16),
        income: 0,
        expenses: 4799.0,
        bills: 6300.0,
        net: -11099.0,
        projectedBalance: 814050.80,
        pressure: 'watch',
      ),
      for (int i = 1; i <= 30; i++)
        PlanningDay(
          date: DateTime(2026, 10, 16).add(Duration(days: i)),
          income: 0,
          expenses: 0,
          bills: 0,
          net: 0,
          projectedBalance: 814050.80,
          pressure: 'clear',
        ),
    ],
  );

  const mockDashboard = DashboardData(
    totalBalance: 825149.80,
    income: 150000.0,
    expenses: 45000.0,
    savings: 25000.0,
    healthScore: 'Good',
    predictedMonthEnd: 814050.80,
    budgetUsedPercent: 30.0,
    categoryExpenses: [],
  );

  testWidgets(
      'planning screen renders 1:1 Figma Affordability Forecasting (Node 85:110)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningProvider.overrideWith((ref) async => mockOverview),
          dashboardProvider.overrideWith((ref) async => mockDashboard),
          billsProvider.overrideWith((ref) async => []),
          goalsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: PlanningScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Title and Header Subtitle (Node 92:38)
    expect(find.text('Affordability Forecasting'), findsOneWidget);
    expect(
      find.text(
          'Simulate any purchase before you spend. Evaluates bill conflicts, cash buffer, and savings goal delays.'),
      findsOneWidget,
    );

    // Hero Card (Node 85:1085)
    expect(find.text('SAFE TO SPEND TODAY'), findsOneWidget);
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Test a purchase'), findsOneWidget);

    // Allocation Card (Node 92:57)
    expect(find.textContaining('WHERE TODAY’S'), findsOneWidget);
    expect(find.textContaining('Free'), findsOneWidget);
    expect(find.textContaining('Goals'), findsOneWidget);
    expect(find.textContaining('Bills'), findsOneWidget);

    // Assumptions Card (Node 92:106)
    expect(find.text('Planned transactions'), findsOneWidget);
  });

  testWidgets('tapping Test a purchase opens KasyaBa purchase simulator modal',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningProvider.overrideWith((ref) async => mockOverview),
          dashboardProvider.overrideWith((ref) async => mockDashboard),
          billsProvider.overrideWith((ref) async => []),
          goalsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: PlanningScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final testButton = find.text('Test a purchase');
    expect(testButton, findsOneWidget);

    await tester.tap(testButton);
    await tester.pumpAndSettle();

    // Modal sheet appears with Evaluate affordability title, tabs, and action button
    expect(find.text('Evaluate affordability'), findsNWidgets(2));
    expect(find.text('Pay in full'), findsOneWidget);
    expect(find.text('Installment'), findsOneWidget);

    // Tap Installment tab -> smooth sliding animation reveals installment tenure & rate
    await tester.tap(find.text('Installment'));
    await tester.pumpAndSettle();

    expect(find.text('INSTALLMENT TENURE'), findsOneWidget);
    expect(find.text('MONTHLY INTEREST RATE'), findsOneWidget);
    expect(find.text('3m'), findsOneWidget);

    // Tap Pay in full -> smooth sliding animation contracts back
    await tester.tap(find.text('Pay in full'));
    await tester.pumpAndSettle();

    expect(find.text('INSTALLMENT TENURE'), findsNothing);
  });
}
