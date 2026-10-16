import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/planning/screens/planning_screen.dart';

void main() {
  final mockOverview = PlanningOverview(
    from: DateTime(2026, 10, 16),
    to: DateTime(2026, 11, 15),
    currentBalance: 29172.0,
    minimumBalanceThreshold: 0.0,
    totalPlannedIncome: 0.0,
    totalPlannedExpenses: 0.0,
    totalUpcomingBills: 6300.0,
    projectedClosingBalance: 22872.0,
    availableBuffer: 22872.0,
    safeToSpendPerDay: 737.81,
    daysInWindow: 31,
    status: 'clear',
    calculationNote:
        'Planning window is 31 days. Daily allowance distributes your free buffer (₱22,872.00) evenly over 31 days.',
    days: [
      PlanningDay(
        date: DateTime(2026, 10, 16),
        income: 0,
        expenses: 0,
        bills: 6300.0,
        net: -6300.0,
        projectedBalance: 22872.0,
        pressure: 'watch',
      ),
      for (int i = 1; i <= 30; i++)
        PlanningDay(
          date: DateTime(2026, 10, 16).add(Duration(days: i)),
          income: 0,
          expenses: 0,
          bills: 0,
          net: 0,
          projectedBalance: 22872.0,
          pressure: 'clear',
        ),
    ],
  );

  testWidgets('planning screen renders daily allowance, narrative, and quiet spans',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningProvider.overrideWith((ref) async => mockOverview),
        ],
        child: const MaterialApp(
          home: PlanningScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Title and Hero
    expect(find.text('Daily Allowance & Runway'), findsOneWidget);
    expect(find.text('DAILY SPENDING ALLOWANCE'), findsOneWidget);
    expect(find.text('₱737.81'), findsWidgets);

    // 3 high-signal cards
    expect(find.text('Current Cash'), findsOneWidget);
    expect(find.text('Due for Bills'), findsOneWidget);
    expect(find.text('Free to Spend'), findsOneWidget);

    // Milestones grouping (collapses 30 quiet days into 1 span tile)
    await tester.scrollUntilVisible(find.text('30 quiet days'), 200);
    expect(find.text('30 quiet days'), findsOneWidget);
    expect(find.text('-₱6,300.00 bills due'), findsOneWidget);

    // Switch to All Days view
    await tester.tap(find.text('All (31)'));
    await tester.pumpAndSettle();

    // Now all days are shown, so quiet span summary pill is gone
    expect(find.text('30 quiet days'), findsNothing);
    expect(find.text('No scheduled activity'), findsWidgets);
  });

  testWidgets('tapping what-if button opens simulator bottom sheet',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planningProvider.overrideWith((ref) async => mockOverview),
        ],
        child: const MaterialApp(
          home: PlanningScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final whatIfButton = find.text('Simulate a "What-If" Purchase');
    expect(whatIfButton, findsOneWidget);

    await tester.tap(whatIfButton);
    await tester.pumpAndSettle();

    // Modal sheet appears
    expect(find.text('What-If Simulator'), findsOneWidget);
    expect(find.text('QUICK PRESETS'), findsOneWidget);
    expect(find.text('SIMULATED IMPACT'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Tap a preset chip
    await tester.tap(find.text('Shopping (-₱5k)'));
    await tester.pumpAndSettle();

    // Check that simulated impact updated
    expect(find.text('FEASIBLE'), findsOneWidget);

    // Close sheet via close button
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('What-If Simulator'), findsNothing);
  });
}
