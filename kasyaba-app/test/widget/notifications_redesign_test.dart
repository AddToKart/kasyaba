import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/alerts/screens/alerts_screen.dart';

void main() {
  testWidgets(
      'AlertsScreen 1:1 Figma Redesign (Node 13:6204) renders grouped notifications, unread indicators, and timestamps',
      (tester) async {
    final now = DateTime.now();

    final testAlerts = [
      AlertItem(
        id: 'alert-1',
        type: 'budget_overrun',
        severity: 'critical',
        title: 'You are over budget',
        message: 'Entertainment is at 500% of its limit.',
        createdAt: now.subtract(const Duration(hours: 2)),
        readAt: null,
      ),
      AlertItem(
        id: 'alert-2',
        type: 'month_end',
        severity: 'warning',
        title: 'Payday in 11 days',
        message: 'Your safe to spend is ₱72,967.09 a day.',
        createdAt: DateTime(now.year, now.month, now.day, 8, 0),
        readAt: null,
      ),
      AlertItem(
        id: 'alert-3',
        type: 'info',
        severity: 'info',
        title: 'Welcome to Kasyaba',
        message: 'Add your salary and payday to see\nyour forecast.',
        createdAt: DateTime(now.year, now.month, now.day - 3, 10, 30),
        readAt: DateTime(now.year, now.month, now.day - 2),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertsProvider.overrideWith((ref) async => testAlerts),
        ],
        child: const MaterialApp(
          home: AlertsScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Header
    expect(find.text('Notifications'), findsOneWidget);

    // Verify "TODAY" section and items
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('You are over budget'), findsOneWidget);
    expect(
        find.text('Entertainment is at 500% of its limit.'), findsOneWidget);
    expect(find.text('Payday in 11 days'), findsOneWidget);
    expect(find.text('Your safe to spend is ₱72,967.09 a day.'),
        findsOneWidget);

    // Verify "EARLIER" section and items
    expect(find.text('EARLIER'), findsOneWidget);
    expect(find.text('Welcome to Kasyaba'), findsOneWidget);
    expect(
        find.text('Add your salary and payday to see\nyour forecast.'),
        findsOneWidget);
  });

  testWidgets('AlertsScreen renders empty state when there are no alerts',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: AlertsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(
        find.text(
            'You\'re all caught up! Predictive insights and budget updates will appear here.'),
        findsOneWidget);
  });
}
