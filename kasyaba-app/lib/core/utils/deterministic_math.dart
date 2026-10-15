import 'dart:math' as math;
import '../providers/api_providers.dart';

/// Individual breakdown of a goal's daily savings requirement.
class GoalContributionDetail {
  final String title;
  final double targetAmount;
  final double currentAmount;
  final double remainingAmount;
  final double dailyRate;
  final int daysCounted;
  final double totalContribution;
  final DateTime? targetDate;

  const GoalContributionDetail({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.dailyRate,
    required this.daysCounted,
    required this.totalContribution,
    this.targetDate,
  });
}

/// Next Payday and Daily Safe-to-Spend Deterministic Models and Calculators.
class DailySafeSpendCalculation {
  final double totalLiquidBalance;
  final double unpaidBillsDue;
  final int unpaidBillsCount;
  final double scheduledGoalContributions;
  final int activeGoalsCount;
  final List<GoalContributionDetail> goalDetails;
  final int daysUntilPayday;
  final DateTime nextPayday;
  final double numerator;
  final double dailySafeSpend;
  final String paydaySchedule;
  final String paydayFrequency;

  const DailySafeSpendCalculation({
    required this.totalLiquidBalance,
    required this.unpaidBillsDue,
    required this.unpaidBillsCount,
    required this.scheduledGoalContributions,
    required this.activeGoalsCount,
    this.goalDetails = const [],
    required this.daysUntilPayday,
    required this.nextPayday,
    required this.numerator,
    required this.dailySafeSpend,
    required this.paydaySchedule,
    required this.paydayFrequency,
  });
}

/// Computes the exact next payday date based on the user's schedule configuration.
DateTime computeNextPayday(DateTime now, {String? frequency, String? schedule}) {
  final today = DateTime(now.year, now.month, now.day);
  final sched = (schedule ?? '15th & 30th').trim();
  final lastDayOfThisMonth = DateTime(today.year, today.month + 1, 0).day;
  final secondPaydayDay = math.min(30, lastDayOfThisMonth);

  if (sched.contains('15th') && sched.contains('30th')) {
    if (today.day < 15) {
      return DateTime(today.year, today.month, 15);
    } else if (today.day < secondPaydayDay) {
      return DateTime(today.year, today.month, secondPaydayDay);
    } else {
      return DateTime(today.year, today.month + 1, 15);
    }
  } else if (sched.contains('1st') && sched.contains('15th')) {
    if (today.day < 15) {
      return DateTime(today.year, today.month, 15);
    } else {
      return DateTime(today.year, today.month + 1, 1);
    }
  } else if (sched.contains('1st')) {
    return DateTime(today.year, today.month + 1, 1);
  } else if (sched.contains('30th') || sched.toLowerCase().contains('end')) {
    if (today.day < secondPaydayDay) {
      return DateTime(today.year, today.month, secondPaydayDay);
    } else {
      final nextMonthLastDay = math.min(30, DateTime(today.year, today.month + 2, 0).day);
      return DateTime(today.year, today.month + 1, nextMonthLastDay);
    }
  } else if (frequency == 'weekly') {
    return today.add(const Duration(days: 7));
  }

  // Fallback default (15th & 30th)
  if (today.day < 15) {
    return DateTime(today.year, today.month, 15);
  } else if (today.day < secondPaydayDay) {
    return DateTime(today.year, today.month, secondPaydayDay);
  } else {
    return DateTime(today.year, today.month + 1, 15);
  }
}

/// Calculates the deterministic "Kasya Ba Today?" Daily Safe-to-Spend metric:
/// Daily Safe Spend = Math.max(0, (Total Liquid Balance - Unpaid Bills Due Before Next Payday - Scheduled Goal Contributions) / Days Until Next Payday)
DailySafeSpendCalculation calculateDailySafeSpend({
  required double totalLiquidBalance,
  required List<BillItem> bills,
  required List<SavingsGoal> goals,
  UserProfile? profile,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final freq = profile?.paydayFrequency ?? 'semi-monthly';
  final sched = profile?.paydaySchedule ?? '15th & 30th';

  final nextPayday = computeNextPayday(today, frequency: freq, schedule: sched);
  final rawDays = nextPayday.difference(today).inDays;
  final daysUntilPayday = rawDays > 0 ? rawDays : 1;

  // Unpaid bills due on or before the next payday (inclusive of the entire payday)
  final endOfPayday = DateTime(nextPayday.year, nextPayday.month, nextPayday.day, 23, 59, 59);
  final unpaidBills = bills.where((b) {
    if (b.status == 'paid') return false;
    return !b.dueDate.isAfter(endOfPayday);
  }).toList();

  final unpaidBillsDue = unpaidBills.fold(0.0, (sum, b) => sum + b.amount);

  // Scheduled goal contributions for this cycle
  var scheduledGoalContributions = 0.0;
  var activeGoalsCount = 0;
  final goalDetails = <GoalContributionDetail>[];
  for (final goal in goals) {
    if (goal.progress >= 1.0) continue;
    activeGoalsCount++;
    final reqMonthly = goal.monthlySavingsRequired;
    double itemContrib = 0.0;
    double dailyRate = 0.0;
    int daysCounted = daysUntilPayday;
    final remainingGoal = math.max(0.0, goal.targetAmount - goal.currentAmount);

    if (reqMonthly != null && reqMonthly > 0) {
      dailyRate = reqMonthly / 30.0;
      itemContrib = dailyRate * daysUntilPayday;
    } else if (goal.daysRemaining != null && goal.daysRemaining! > 0) {
      dailyRate = remainingGoal / goal.daysRemaining!;
      daysCounted = math.min(daysUntilPayday, goal.daysRemaining!);
      itemContrib = dailyRate * daysCounted;
    }

    if (itemContrib > 0) {
      scheduledGoalContributions += itemContrib;
      final parsedDate = goal.targetDate != null ? DateTime.tryParse(goal.targetDate!) : null;
      goalDetails.add(
        GoalContributionDetail(
          title: goal.name,
          targetAmount: goal.targetAmount,
          currentAmount: goal.currentAmount,
          remainingAmount: remainingGoal,
          dailyRate: dailyRate,
          daysCounted: daysCounted,
          totalContribution: itemContrib,
          targetDate: parsedDate,
        ),
      );
    }
  }

  final numerator = totalLiquidBalance - unpaidBillsDue - scheduledGoalContributions;
  final dailySafeSpend = math.max(0.0, numerator / daysUntilPayday);

  return DailySafeSpendCalculation(
    totalLiquidBalance: totalLiquidBalance,
    unpaidBillsDue: unpaidBillsDue,
    unpaidBillsCount: unpaidBills.length,
    scheduledGoalContributions: scheduledGoalContributions,
    activeGoalsCount: activeGoalsCount,
    goalDetails: goalDetails,
    daysUntilPayday: daysUntilPayday,
    nextPayday: nextPayday,
    numerator: numerator,
    dailySafeSpend: dailySafeSpend,
    paydaySchedule: sched,
    paydayFrequency: freq,
  );
}

/// Work-Hours Equivalent life-energy cost calculation.
class WorkHoursEquivalent {
  final double? salaryAmount;
  final double hourlyWage;
  final double workHours;
  final double workDays;
  final bool hasSalary;

  const WorkHoursEquivalent({
    required this.salaryAmount,
    required this.hourlyWage,
    required this.workHours,
    required this.workDays,
    required this.hasSalary,
  });
}

/// Calculates the exact work-hours life-energy cost based on 22 days/month @ 8 hours/day = 176 hours/month.
WorkHoursEquivalent calculateWorkHoursEquivalent({
  required double itemPrice,
  required double? monthlySalary,
}) {
  if (monthlySalary == null || monthlySalary <= 0 || itemPrice <= 0) {
    return const WorkHoursEquivalent(
      salaryAmount: null,
      hourlyWage: 0.0,
      workHours: 0.0,
      workDays: 0.0,
      hasSalary: false,
    );
  }

  final hourlyWage = monthlySalary / 176.0;
  final workHours = itemPrice / hourlyWage;
  final workDays = workHours / 8.0;

  return WorkHoursEquivalent(
    salaryAmount: monthlySalary,
    hourlyWage: hourlyWage,
    workHours: workHours,
    workDays: workDays,
    hasSalary: true,
  );
}

/// Cash vs. Installment / BNPL Comparator Calculation.
class InstallmentComparison {
  final double purchaseAmount;
  final int tenureMonths;
  final double monthlyInterestRatePercent;
  final double monthlyInterestAmount;
  final double totalInterest;
  final double totalCost;
  final double monthlyInstallment;
  final double cashPreservedToday;
  final double cashDailySafeSpendImpact;
  final double installmentDailySafeSpendImpact;
  final double currentBalance;
  final double postCashBalance;

  const InstallmentComparison({
    required this.purchaseAmount,
    required this.tenureMonths,
    required this.monthlyInterestRatePercent,
    required this.monthlyInterestAmount,
    required this.totalInterest,
    required this.totalCost,
    required this.monthlyInstallment,
    required this.cashPreservedToday,
    required this.cashDailySafeSpendImpact,
    required this.installmentDailySafeSpendImpact,
    required this.currentBalance,
    required this.postCashBalance,
  });
}

/// Deterministic comparator calculating immediate cash impact, cash preserved, interest penalty,
/// and daily safe spend reduction between paying full cash vs installment.
InstallmentComparison calculateInstallmentComparison({
  required double purchaseAmount,
  required int tenureMonths,
  required double monthlyInterestRatePercent,
  required double currentBalance,
  required int daysUntilPayday,
}) {
  final days = math.max(1, daysUntilPayday);
  final monthlyInterest = purchaseAmount * (monthlyInterestRatePercent / 100.0);
  final totalInterest = monthlyInterest * tenureMonths;
  final totalCost = purchaseAmount + totalInterest;
  final monthlyInstallment = tenureMonths > 0 ? totalCost / tenureMonths : totalCost;
  final cashPreserved = math.max(0.0, purchaseAmount - monthlyInstallment);

  final cashDailyImpact = purchaseAmount / days;
  final installmentDailyImpact = monthlyInstallment / days;

  return InstallmentComparison(
    purchaseAmount: purchaseAmount,
    tenureMonths: tenureMonths,
    monthlyInterestRatePercent: monthlyInterestRatePercent,
    monthlyInterestAmount: monthlyInterest,
    totalInterest: totalInterest,
    totalCost: totalCost,
    monthlyInstallment: monthlyInstallment,
    cashPreservedToday: cashPreserved,
    cashDailySafeSpendImpact: cashDailyImpact,
    installmentDailySafeSpendImpact: installmentDailyImpact,
    currentBalance: currentBalance,
    postCashBalance: currentBalance - purchaseAmount,
  );
}

