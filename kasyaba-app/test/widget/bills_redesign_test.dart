import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/bills/screens/add_bill_screen.dart';
import 'package:kasyaba/features/bills/screens/bills_screen.dart';

void main() {
  final sampleBills = [
    BillItem(
      id: 'bill-1',
      name: 'Internet (Fiber)',
      amount: 1699.0,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: 'upcoming',
    ),
    BillItem(
      id: 'bill-2',
      name: 'Electricity',
      amount: 3450.0,
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'overdue',
    ),
    BillItem(
      id: 'bill-3',
      name: 'Water Utility',
      amount: 450.0,
      dueDate: DateTime.now().subtract(const Duration(days: 10)),
      status: 'paid',
    ),
  ];

  final sampleAccounts = [
    const Account(
      id: 'acc-1',
      name: 'BDO Checking',
      type: 'bank',
    ),
    const Account(
      id: 'acc-2',
      name: 'GCash Wallet',
      type: 'e-wallet',
    ),
  ];

  testWidgets('BillsScreen 1:1 Figma Redesign renders controls, filters, and bills', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billsProvider.overrideWith((ref) => Future.value(sampleBills)),
          accountsProvider.overrideWith((ref) => Future.value(sampleAccounts)),
        ],
        child: const MaterialApp(
          home: BillsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Top Actions
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Show full month'), findsOneWidget);

    // Verify 3-way filter capsule
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);

    // Upcoming bill item should be visible in 'Upcoming' tab
    expect(find.text('Internet (Fiber)'), findsOneWidget);
    expect(find.text('QUICK ADD'), findsOneWidget);
    expect(find.text('Electricity'), findsWidgets);

    // Toggle to full month view
    await tester.tap(find.text('Show full month'));
    await tester.pumpAndSettle();
    expect(find.text('Show week'), findsOneWidget);

    // Switch filter to 'Paid'
    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();
    expect(find.text('Water Utility'), findsOneWidget);

    // Switch filter to 'Overdue'
    await tester.tap(find.text('Overdue'));
    await tester.pumpAndSettle();
    expect(find.text('Electricity'), findsWidgets);
  });

  testWidgets('AddBillScreen 1:1 Figma Redesign renders form cards and chips', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith((ref) => Future.value(sampleAccounts)),
        ],
        child: const MaterialApp(
          home: AddBillScreen(initialName: 'Netflix'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify screen title & prefilled name
    expect(find.text('New bill'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);

    // Verify repeat chips
    expect(find.text('REPEATS'), findsOneWidget);
    expect(find.text('Once'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);

    // Verify reminder chips
    expect(find.text('REMIND ME'), findsOneWidget);
    expect(find.text('On the day'), findsOneWidget);
    expect(find.text('1 day before'), findsOneWidget);
    expect(find.text('3 days before'), findsOneWidget);
    expect(find.text('1 week before'), findsOneWidget);

    // Verify Save bill CTA
    expect(find.text('Save bill'), findsOneWidget);
  });
}
