import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/budgets/screens/budgets_screen.dart';

void main() {
  final sampleEmptyStatus = BudgetStatus(
    month: '2026-11',
    totalBudget: 0.0,
    totalSpent: 0.0,
    overallPercent: 0.0,
    budgetCount: 0,
    budgets: [],
  );

  final sampleActiveStatus = BudgetStatus(
    month: '2026-11',
    totalBudget: 15000.0,
    totalSpent: 4500.0,
    overallPercent: 30.0,
    budgetCount: 2,
    budgets: [
      BudgetItemStatus(
        budgetId: 'b1',
        categoryId: 'cat_food',
        amount: 10000.0,
        spent: 3500.0,
        remaining: 6500.0,
        percentUsed: 35.0,
        status: 'on_track',
      ),
      BudgetItemStatus(
        budgetId: 'b2',
        categoryId: 'cat_utilities',
        amount: 5000.0,
        spent: 1000.0,
        remaining: 4000.0,
        percentUsed: 20.0,
        status: 'on_track',
      ),
    ],
  );

  final sampleCategories = [
    const Category(id: 'cat_food', name: 'Food & Dining', iconKey: 'restaurant'),
    const Category(id: 'cat_utilities', name: 'Utilities', iconKey: 'power'),
  ];

  testWidgets('BudgetsScreen renders empty state with luxury tokens and CTA', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetStatusProvider.overrideWith((ref) => Future.value(sampleEmptyStatus)),
          categoriesProvider.overrideWith((ref) => Future.value(sampleCategories)),
        ],
        child: const MaterialApp(home: BudgetsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Monthly Budget Overview'), findsOneWidget);
    expect(find.text('0% Used'), findsOneWidget);
    expect(find.text('No Category Budgets Set'), findsOneWidget);
    expect(find.text('Set Category Budget'), findsOneWidget);
    expect(find.text('New Budget'), findsOneWidget);
  });

  testWidgets('BudgetsScreen renders category budget items and hero overview', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetStatusProvider.overrideWith((ref) => Future.value(sampleActiveStatus)),
          categoriesProvider.overrideWith((ref) => Future.value(sampleCategories)),
        ],
        child: const MaterialApp(home: BudgetsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Monthly Budget Overview'), findsOneWidget);
    expect(find.text('30% Used'), findsOneWidget);
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('Utilities'), findsOneWidget);
    expect(find.text('35%'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('New Budget'), findsOneWidget);
  });

  testWidgets('Tapping New Budget opens bottom sheet with clean inputs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetStatusProvider.overrideWith((ref) => Future.value(sampleActiveStatus)),
          categoriesProvider.overrideWith((ref) => Future.value(sampleCategories)),
        ],
        child: const MaterialApp(home: BudgetsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final newBudgetButton = find.text('New Budget');
    expect(newBudgetButton, findsOneWidget);
    await tester.tap(newBudgetButton);
    await tester.pumpAndSettle();

    expect(find.text('Create budget'), findsOneWidget);
    expect(find.text('Monthly Limit'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Create Budget'), findsOneWidget);
  });
}
