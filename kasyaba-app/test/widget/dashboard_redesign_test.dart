import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/auth/auth_provider.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/dashboard/screens/dashboard_screen.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('DashboardScreen 1:1 Figma Redesign (Node 11:5943)', () {
    testWidgets('renders all Figma sections: Header, Safe Spend Hero, Stats, KasyaBa CTA, Forecast, Spending, More', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testDashboardData = DashboardData(
        totalBalance: 825149.80,
        income: 1000000.0,
        expenses: 123000.0,
        savings: 60000.0,
        budgetUsedPercent: 122.0,
        healthScore: 'Good',
        predictedMonthEnd: 757499.80,
        categoryExpenses: [
          CategoryExpenseSummary(
            categoryName: 'Shopping',
            total: 51000.0,
          ),
          CategoryExpenseSummary(
            categoryName: 'Entertainment',
            total: 50000.0,
          ),
          CategoryExpenseSummary(
            categoryName: 'Education',
            total: 17000.0,
          ),
        ],
      );

      final testGoals = [
        const SavingsGoal(
          id: 'g1',
          name: 'Emergency Fund',
          targetAmount: 200000.0,
          currentAmount: 50000.0,
          daysRemaining: 180,
        ),
      ];

      final testBills = [
        BillItem(
          id: 'b1',
          name: 'Electric Meralco',
          amount: 4500.0,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          status: 'unpaid',
        ),
      ];

      final testTransactions = [
        TransactionEntry(
          id: 't1',
          title: 'Salary Deposit',
          amount: 1000000.0,
          isExpense: false,
          categoryName: 'Salary',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(
                const AuthState(
                  isAuthenticated: true,
                  displayName: 'Mary Jane',
                ),
              ),
            ),
            dashboardProvider.overrideWith((ref) => testDashboardData),
            userProfileProvider.overrideWith(
              (ref) => const UserProfile(
                id: 'u1',
                email: 'mary@example.com',
                paydaySchedule: '15th & 30th',
              ),
            ),
            billsProvider.overrideWith((ref) => testBills),
            goalsProvider.overrideWith((ref) => testGoals),
            transactionsProvider.overrideWith((ref) => testTransactions),
            budgetStatusProvider.overrideWith((ref) => BudgetStatus.empty()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header Bar: Initial "M", name "Mary"
      expect(find.text('M'), findsOneWidget);
      expect(find.text('Mary'), findsOneWidget);

      // 2. Hero Card: "DAILY SAFE SPEND", "Total balance", formatted values
      expect(find.text('DAILY SAFE SPEND'), findsOneWidget);
      expect(find.text('Total balance'), findsOneWidget);
      expect(find.text('₱825,149.80'), findsOneWidget);

      // Verify Quick Action buttons: Expense and Income ONLY (NO Transfer)
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Transfer'), findsNothing);

      // 3. Quick Stat Cards: Saved, Budget used, Buffer
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Budget used'), findsOneWidget);
      expect(find.text('Buffer'), findsOneWidget);

      // 4. "KasyaBa?" CTA Card
      expect(find.text('KasyaBa?'), findsOneWidget);
      expect(find.text('Test a purchase if you can afford it.'), findsOneWidget);

      // 5. "Month-end forecast" Card
      expect(find.text('Month-end forecast'), findsOneWidget);
      expect(find.text('₱757,499.80'), findsOneWidget);
      expect(find.text('Bills covered'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
      expect(find.text('Projected'), findsOneWidget);
      expect(find.text('Bill due'), findsOneWidget);

      // 6. "Spending this month" Card
      expect(find.text('Spending this month'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.text('Education'), findsOneWidget);
      expect(find.text('₱51,000.00'), findsOneWidget);

      // 7. "More" Card
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Recent activity'), findsOneWidget);
    });
  });
}
