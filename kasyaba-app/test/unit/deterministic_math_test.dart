import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/core/utils/deterministic_math.dart';

void main() {
  group('computeNextPayday', () {
    test('calculates 15th if today is before the 15th', () {
      final now = DateTime(2026, 10, 5);
      final nextPayday = computeNextPayday(now, schedule: '15th & 30th');
      expect(nextPayday.year, 2026);
      expect(nextPayday.month, 10);
      expect(nextPayday.day, 15);
    });

    test('calculates 30th if today is after the 15th and before the 30th (14 days left)', () {
      final now = DateTime(2026, 10, 16);
      final nextPayday = computeNextPayday(now, schedule: '15th & 30th');
      expect(nextPayday.year, 2026);
      expect(nextPayday.month, 10);
      expect(nextPayday.day, 30);
      expect(nextPayday.difference(now).inDays, 14);
    });

    test('calculates 15th of next month if today is past 30th', () {
      final now = DateTime(2026, 10, 31);
      final nextPayday = computeNextPayday(now, schedule: '15th & 30th');
      expect(nextPayday.year, 2026);
      expect(nextPayday.month, 11);
      expect(nextPayday.day, 15);
    });

    test('handles February correctly for 30th schedule (clamps to 28)', () {
      final now = DateTime(2026, 2, 16);
      final nextPayday = computeNextPayday(now, schedule: '15th & 30th');
      expect(nextPayday.year, 2026);
      expect(nextPayday.month, 2);
      expect(nextPayday.day, 28);
    });

    test('handles 1st & 15th schedule', () {
      final now = DateTime(2026, 10, 10);
      final nextPayday = computeNextPayday(now, schedule: '1st & 15th');
      expect(nextPayday.day, 15);

      final now2 = DateTime(2026, 10, 20);
      final nextPayday2 = computeNextPayday(now2, schedule: '1st & 15th');
      expect(nextPayday2.month, 11);
      expect(nextPayday2.day, 1);
    });
  });

  group('calculateDailySafeSpend', () {
    test('calculates exact daily safe spend with bills and goal contributions', () {
      // Oct 16 to Oct 30 -> 14 days
      final now = DateTime(2026, 10, 16);
      final bills = [
        BillItem(
          id: '1',
          name: 'Internet',
          amount: 1500.0,
          dueDate: DateTime(2026, 10, 25),
          status: 'upcoming',
        ),
        BillItem(
          id: '2',
          name: 'Electricity (Due After Payday)',
          amount: 3000.0,
          dueDate: DateTime(2026, 11, 5),
          status: 'upcoming',
        ),
        BillItem(
          id: '3',
          name: 'Water (Already Paid)',
          amount: 500.0,
          dueDate: DateTime(2026, 10, 20),
          status: 'paid',
        ),
      ];

      final goals = [
        const SavingsGoal(
          id: 'g1',
          name: 'Emergency Fund',
          targetAmount: 50000,
          currentAmount: 10000,
          monthlySavingsRequired: 3000.0,
        ),
      ];

      // totalLiquidBalance = 10,000
      // unpaidBillsDue before Oct 30 = 1500 (Electricity is after, Water is paid)
      // scheduledGoalContributions for 14 days = (3000 / 30) * 14 = 1400.0
      // Numerator = 10,000 - 1500 - 1400 = 7100.0
      // Days = 14
      // Daily Safe Spend = 7100 / 14 = 507.1428...
      final calc = calculateDailySafeSpend(
        totalLiquidBalance: 10000.0,
        bills: bills,
        goals: goals,
        profile: const UserProfile(
          id: 'u1',
          email: 'test@example.com',
          paydaySchedule: '15th & 30th',
          paydayFrequency: 'semi-monthly',
        ),
        now: now,
      );

      expect(calc.daysUntilPayday, 14);
      expect(calc.unpaidBillsDue, 1500.0);
      expect(calc.unpaidBillsCount, 1);
      expect(calc.scheduledGoalContributions, closeTo(1400.0, 0.001));
      expect(calc.numerator, closeTo(7100.0, 0.001));
      expect(calc.dailySafeSpend, closeTo(507.14, 0.01));
    });

    test('clamps negative numerator to 0 daily safe spend', () {
      final now = DateTime(2026, 10, 16);
      final bills = [
        BillItem(
          id: '1',
          name: 'Rent',
          amount: 15000.0,
          dueDate: DateTime(2026, 10, 20),
          status: 'upcoming',
        ),
      ];

      final calc = calculateDailySafeSpend(
        totalLiquidBalance: 5000.0,
        bills: bills,
        goals: [],
        now: now,
      );

      expect(calc.numerator, -10000.0);
      expect(calc.dailySafeSpend, 0.0);
    });
  });

  group('calculateWorkHoursEquivalent', () {
    test('calculates work-hours and workdays accurately for monthly salary', () {
      // Monthly Salary = 44,000
      // Hourly Wage = 44,000 / 176 = 250.00 / hr
      // Item Price = 21,125
      // Work Hours = 21,125 / 250 = 84.5 hours
      // Workdays = 84.5 / 8 = 10.5625 days (~10.6 workdays)
      final result = calculateWorkHoursEquivalent(
        itemPrice: 21125.0,
        monthlySalary: 44000.0,
      );

      expect(result.hasSalary, true);
      expect(result.hourlyWage, 250.0);
      expect(result.workHours, 84.5);
      expect(result.workDays, closeTo(10.56, 0.01));
    });

    test('returns hasSalary false when salary is null or 0', () {
      final res1 = calculateWorkHoursEquivalent(
        itemPrice: 5000.0,
        monthlySalary: null,
      );
      expect(res1.hasSalary, false);
      expect(res1.workHours, 0.0);

      final res2 = calculateWorkHoursEquivalent(
        itemPrice: 5000.0,
        monthlySalary: 0.0,
      );
      expect(res2.hasSalary, false);
    });
  });

  group('calculateInstallmentComparison', () {
    test('calculates 0% BNPL installment correctly', () {
      // Item Price = 12,000, 3 months, 0% interest
      // Monthly Installment = 4,000
      // Cash Preserved Today = 12,000 - 4,000 = 8,000
      // Total Interest = 0
      // Total Cost = 12,000
      final result = calculateInstallmentComparison(
        purchaseAmount: 12000.0,
        tenureMonths: 3,
        monthlyInterestRatePercent: 0.0,
        currentBalance: 20000.0,
        daysUntilPayday: 14,
      );

      expect(result.monthlyInstallment, 4000.0);
      expect(result.totalInterest, 0.0);
      expect(result.totalCost, 12000.0);
      expect(result.cashPreservedToday, 8000.0);
      expect(result.cashDailySafeSpendImpact, closeTo(12000 / 14, 0.01));
      expect(result.installmentDailySafeSpendImpact, closeTo(4000 / 14, 0.01));
    });

    test('calculates interest-bearing BNPL installment correctly', () {
      // Item Price = 10,000, 6 months, 3% monthly interest
      // Monthly Interest = 10,000 * 0.03 = 300
      // Total Interest = 300 * 6 = 1,800
      // Total Cost = 11,800
      // Monthly Installment = 11,800 / 6 = 1966.67
      // Cash Preserved Today = 10,000 - 1966.67 = 8033.33
      final result = calculateInstallmentComparison(
        purchaseAmount: 10000.0,
        tenureMonths: 6,
        monthlyInterestRatePercent: 3.0,
        currentBalance: 25000.0,
        daysUntilPayday: 14,
      );

      expect(result.monthlyInterestAmount, 300.0);
      expect(result.totalInterest, 1800.0);
      expect(result.totalCost, 11800.0);
      expect(result.monthlyInstallment, closeTo(1966.67, 0.01));
      expect(result.cashPreservedToday, closeTo(8033.33, 0.01));
    });
  });
}

