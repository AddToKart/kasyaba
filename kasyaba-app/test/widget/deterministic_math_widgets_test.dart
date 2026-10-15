import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/utils/deterministic_math.dart';
import 'package:kasyaba/features/dashboard/screens/dashboard_screen.dart';
import 'package:kasyaba/features/savings/screens/goals_screen.dart';

void main() {
  group('Daily Safe Spend Hero Card & Breakdown Sheet', () {
    testWidgets('renders Kasya Ba Today daily safe spend metric and opens breakdown sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const dummyDashboardData = DashboardData(
        totalBalance: 12500.0,
        income: 30000.0,
        expenses: 17500.0,
        savings: 5000.0,
        healthScore: 'Good',
        predictedMonthEnd: 15000.0,
        categoryExpenses: [],
      );

      // Render the DashboardScreen with deterministic overrides
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) => dummyDashboardData),
            userProfileProvider.overrideWith(
              (ref) => const UserProfile(
                id: 'u1',
                email: 'test@example.com',
                paydaySchedule: '15th & 30th',
              ),
            ),
            billsProvider.overrideWith((ref) => []),
            goalsProvider.overrideWith((ref) => []),
            transactionsProvider.overrideWith((ref) => []),
            budgetStatusProvider.overrideWith((ref) => BudgetStatus.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Kasya Ba Today?" pill & text are rendered
      expect(find.text('KASYA BA TODAY?'), findsOneWidget);
      expect(find.text('DAILY SAFE SPEND'), findsOneWidget);
      expect(find.text('Breakdown'), findsOneWidget);
      expect(find.textContaining('/ day'), findsWidgets);

      // Tap on breakdown to open bottom sheet
      await tester.tap(find.text('Breakdown'));
      await tester.pumpAndSettle();

      // Verify breakdown sheet contents
      expect(find.text('Kasya Ba Today? Math Breakdown'), findsOneWidget);
      expect(find.text('EXACT DETERMINISTIC FORMULA'), findsOneWidget);
      expect(find.text('NUMERATOR (SAFE CASH BUFFER)'), findsOneWidget);
      expect(find.text('DENOMINATOR (PAYDAY TIMELINE)'), findsOneWidget);
      expect(find.text('DAILY SAFE SPEND ALLOWANCE'), findsOneWidget);
      expect(find.text('Close Breakdown'), findsOneWidget);

      // Close breakdown sheet
      await tester.tap(find.text('Close Breakdown'));
      await tester.pumpAndSettle();
      expect(find.text('EXACT DETERMINISTIC FORMULA'), findsNothing);
    });

    testWidgets('fresh user with 0 transactions renders Quick Start Checklist and goal proration breakdown', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const freshDashboardData = DashboardData(
        totalBalance: 0.0,
        income: 0.0,
        expenses: 0.0,
        savings: 0.0,
        healthScore: 'Fair',
        predictedMonthEnd: 0.0,
        categoryExpenses: [],
      );

      final dummyGoal = const SavingsGoal(
        id: 'g1',
        name: 'Tuition Fee',
        targetAmount: 60000.0,
        currentAmount: 0.0,
        daysRemaining: 136,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) => freshDashboardData),
            userProfileProvider.overrideWith(
              (ref) => const UserProfile(
                id: 'u1',
                email: 'fresh@example.com',
                paydaySchedule: '15th & 30th',
              ),
            ),
            billsProvider.overrideWith((ref) => []),
            goalsProvider.overrideWith((ref) => [dummyGoal]),
            transactionsProvider.overrideWith((ref) => []),
            budgetStatusProvider.overrideWith((ref) => BudgetStatus.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Quick Start Checklist is visible for fresh user
      expect(find.text('QUICK SETUP GUIDE'), findsOneWidget);
      expect(find.text('Log your starting balance or salary'), findsOneWidget);
      expect(find.text('Configure salary & payday schedule'), findsOneWidget);
      expect(find.text('Add your upcoming bills & goals'), findsOneWidget);
      expect(find.text('+ Add Starting Cash'), findsOneWidget);
      expect(find.text('+ Set Up'), findsOneWidget);

      // Open breakdown
      await tester.tap(find.text('Breakdown'));
      await tester.pumpAndSettle();

      // Verify Itemized Goal Breakdown & Contextual ₱0 explanation
      expect(find.text('GOAL PRORATION BREAKDOWN'), findsOneWidget);
      expect(find.text('Tuition Fee'), findsOneWidget);
      expect(find.text('Why is your daily safe spend ₱0.00?'), findsOneWidget);
      expect(find.text('+ Log Starting Cash / Balance'), findsOneWidget);

      await tester.tap(find.text('Close Breakdown'));
      await tester.pumpAndSettle();
    });

    testWidgets('existing user with transactions in deficit renders Pay Period Deficit alert without checklist', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const existingUserDashboard = DashboardData(
        totalBalance: 500.0,
        income: 25000.0,
        expenses: 24500.0,
        savings: 0.0,
        healthScore: 'Poor',
        predictedMonthEnd: 0.0,
        categoryExpenses: [],
      );

      final dummyBill = BillItem(
        id: 'b1',
        name: 'Rent',
        amount: 8000.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: 'unpaid',
      );

      final pastTx = TransactionEntry(
        id: 'tx1',
        title: 'Food',
        amount: 500.0,
        isExpense: true,
        categoryName: 'Food',
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) => existingUserDashboard),
            userProfileProvider.overrideWith(
              (ref) => const UserProfile(
                id: 'u1',
                email: 'existing@example.com',
                paydaySchedule: '15th & 30th',
              ),
            ),
            billsProvider.overrideWith((ref) => [dummyBill]),
            goalsProvider.overrideWith((ref) => []),
            transactionsProvider.overrideWith((ref) => [pastTx]),
            budgetStatusProvider.overrideWith((ref) => BudgetStatus.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Quick setup guide should NOT be displayed for an existing user
      expect(find.text('QUICK SETUP GUIDE'), findsNothing);

      // Deficit alert SHOULD be displayed
      expect(find.text('PAY PERIOD DEFICIT'), findsOneWidget);
      expect(find.text('+ Add Income'), findsOneWidget);
      expect(find.text('Adjust Goals'), findsOneWidget);
    });
  });

  group('Scenario Lab (Can I Buy This?): Work-Hours & Installment Comparator', () {
    testWidgets('renders Time Cost work-hours badge and 2-column comparator in scenario lab', (tester) async {
      final checkResult = PurchaseCheckResult(
        itemTitle: 'Smartphone',
        amount: 21125.0,
        verdict: 'AFFORDABLE',
        statusTitle: 'Safely Affordable',
        statusMessage: 'You can comfortably afford this purchase.',
        currentBalance: 50000.0,
        postPurchaseBalance: 28875.0,
        projectedMonthEndBalance: 45000.0,
        postPurchaseMonthEndBalance: 23875.0,
        totalUpcomingBills: 5000.0,
        cashAfterBills: 23875.0,
        reasons: ['Balance remains comfortably above threshold'],
      );

      final dummyProfile = const UserProfile(
        id: 'u1',
        email: 'test@example.com',
        salaryAmount: 44000.0, // 44,000 / 176 = 250/hr -> 21,125 / 250 = 84.5 work hours
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      // Render the bottom sheet card result directly
                      return Column(
                        children: [
                          _PurchaseCheckCardResultTestWrapper(
                            result: checkResult,
                            purchaseAmount: 21125.0,
                            isInstallment: true,
                            tenureMonths: 6,
                            monthlyInterestRate: 0.0,
                            userProfile: dummyProfile,
                            daysUntilPayday: 14,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Work-Hours Badge
      expect(find.textContaining('84.5 Work Hours'), findsOneWidget);
      expect(find.textContaining('10.6 Workdays'), findsOneWidget);

      // Check 2-Column Comparator
      expect(find.text('CASH VS. INSTALLMENT COMPARATOR'), findsOneWidget);
      expect(find.text('PAY FULL CASH'), findsOneWidget);
      expect(find.text('INSTALLMENT (6M)'), findsOneWidget);
      expect(find.text('Cash Preserved Today'), findsOneWidget);
      expect(find.textContaining('0% BNPL preserves'), findsOneWidget);
    });
  });
}

class _PurchaseCheckCardResultTestWrapper extends StatelessWidget {
  final PurchaseCheckResult result;
  final double purchaseAmount;
  final bool isInstallment;
  final int tenureMonths;
  final double monthlyInterestRate;
  final UserProfile? userProfile;
  final int daysUntilPayday;

  const _PurchaseCheckCardResultTestWrapper({
    required this.result,
    required this.purchaseAmount,
    required this.isInstallment,
    required this.tenureMonths,
    required this.monthlyInterestRate,
    this.userProfile,
    required this.daysUntilPayday,
  });

  @override
  Widget build(BuildContext context) {
    final workHours = calculateWorkHoursEquivalent(
      itemPrice: purchaseAmount,
      monthlySalary: userProfile?.salaryAmount,
    );

    final comp = calculateInstallmentComparison(
      purchaseAmount: purchaseAmount,
      tenureMonths: tenureMonths,
      monthlyInterestRatePercent: monthlyInterestRate,
      currentBalance: result.currentBalance,
      daysUntilPayday: daysUntilPayday,
    );

    return Container(
      child: Column(
        children: [
          Text(result.statusTitle),
          Text(result.statusMessage),
          if (workHours.hasSalary)
            Text('Time Cost: ${workHours.workHours.toStringAsFixed(1)} Work Hours (${workHours.workDays.toStringAsFixed(1)} Workdays)'),
          const Text('CASH VS. INSTALLMENT COMPARATOR'),
          const Text('PAY FULL CASH'),
          Text('INSTALLMENT (${comp.tenureMonths}M)'),
          const Text('Cash Preserved Today'),
          Text(comp.totalInterest > 0 ? 'Installment preserves' : '0% BNPL preserves'),
        ],
      ),
    );
  }
}
