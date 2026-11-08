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
///
/// Supports weekly/bi-weekly frequencies, end-of-month schedules, arbitrary
/// single or paired day-of-month schedules (e.g. `10th & 25th`), and custom
/// schedules that embed a day number (e.g. `Custom: 20th`). Unrecognized
/// schedules fall back to the standard `15th & 30th` PH schedule.
DateTime computeNextPayday(
  DateTime now, {
  String? frequency,
  String? schedule,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final normalizedFrequency = (frequency ?? '').trim().toLowerCase();

  if (normalizedFrequency == 'weekly') {
    return today.add(const Duration(days: 7));
  }
  if (normalizedFrequency == 'bi-weekly' || normalizedFrequency == 'biweekly') {
    return today.add(const Duration(days: 14));
  }

  final sched = (schedule ?? '15th & 30th').trim();
  final lowerSched = sched.toLowerCase();

  // Preserve the historical end-of-month behavior (clamped to day 30).
  if (lowerSched.contains('end')) {
    final lastDayOfThisMonth = DateTime(today.year, today.month + 1, 0).day;
    final secondPaydayDay = math.min(30, lastDayOfThisMonth);
    if (today.day < secondPaydayDay) {
      return DateTime(today.year, today.month, secondPaydayDay);
    }
    final nextMonthLastDay = math.min(
      30,
      DateTime(today.year, today.month + 2, 0).day,
    );
    return DateTime(today.year, today.month + 1, nextMonthLastDay);
  }

  final parsedDays =
      RegExp(r'\d{1,2}')
          .allMatches(sched)
          .map((match) => int.tryParse(match.group(0) ?? ''))
          .whereType<int>()
          .where((day) => day >= 1 && day <= 31)
          .toSet()
          .toList()
        ..sort();

  if (parsedDays.isNotEmpty) {
    return _nextOccurrenceForDays(today, parsedDays);
  }

  // Fallback default (15th & 30th).
  return _nextOccurrenceForDays(today, const <int>[15, 30]);
}

/// Returns the first configured day-of-month occurrence strictly after [today].
DateTime _nextOccurrenceForDays(DateTime today, List<int> days) {
  final sortedDays = List<int>.from(days)..sort();
  for (var monthOffset = 0; monthOffset <= 1; monthOffset++) {
    final monthStart = DateTime(today.year, today.month + monthOffset, 1);
    final lastDayOfMonth = DateTime(
      monthStart.year,
      monthStart.month + 1,
      0,
    ).day;
    for (final day in sortedDays) {
      final candidate = DateTime(
        monthStart.year,
        monthStart.month,
        math.min(day, lastDayOfMonth),
      );
      if (candidate.isAfter(today)) {
        return candidate;
      }
    }
  }

  final nextMonth = DateTime(today.year, today.month + 1, 1);
  final lastDayOfNextMonth = DateTime(
    nextMonth.year,
    nextMonth.month + 1,
    0,
  ).day;
  return DateTime(
    nextMonth.year,
    nextMonth.month,
    math.min(sortedDays.first, lastDayOfNextMonth),
  );
}

/// Unified monthly savings need for a goal.
///
/// Prefers the server-provided monthly requirement, then the server-provided
/// remaining days, then the goal target date, and finally a 365-day horizon.
double goalMonthlyNeed(SavingsGoal goal) {
  final requiredMonthly = goal.monthlySavingsRequired;
  if (requiredMonthly != null && requiredMonthly > 0) {
    return requiredMonthly;
  }

  final remaining = math.max(0.0, goal.targetAmount - goal.currentAmount);
  if (remaining <= 0) return 0.0;

  final daysRemaining = goal.daysRemaining;
  if (daysRemaining != null && daysRemaining > 0) {
    return remaining / daysRemaining * 30;
  }

  final now = DateTime.now();
  final targetDate = goal.targetDate != null
      ? DateTime.tryParse(goal.targetDate!)
      : null;
  if (targetDate != null && targetDate.isAfter(now)) {
    final daysUntilTarget = math.max(1, targetDate.difference(now).inDays);
    return remaining / daysUntilTarget * 30;
  }

  return remaining / 365 * 30;
}

/// Days remaining for a goal using the same priority chain as
/// [goalMonthlyNeed]: server-provided [SavingsGoal.daysRemaining], then the
/// target date, otherwise null (open-ended horizon).
///
/// Horizons shorter than 31 days make a "per month" figure read absurd (it
/// can exceed the goal itself), so UI callers treat that range as a
/// short-horizon and display a per-day pace instead.
int? goalDaysUntilTarget(SavingsGoal goal, {DateTime? now}) {
  if (goal.daysRemaining != null && goal.daysRemaining! > 0) {
    return goal.daysRemaining;
  }

  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final targetDate = goal.targetDate != null
      ? DateTime.tryParse(goal.targetDate!)
      : null;
  if (targetDate != null) {
    final days = targetDate.difference(today).inDays;
    if (days > 0) return days;
  }
  return null;
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
  final endOfPayday = DateTime(
    nextPayday.year,
    nextPayday.month,
    nextPayday.day,
    23,
    59,
    59,
  );
  final unpaidBills = bills.where((b) {
    // Paid and cancelled instances no longer represent money that must be
    // reserved before payday, so neither may reduce safe-to-spend.
    final status = b.status.trim().toLowerCase();
    if (status == 'paid' || status == 'cancelled') return false;
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
      final parsedDate = goal.targetDate != null
          ? DateTime.tryParse(goal.targetDate!)
          : null;
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

  final numerator =
      totalLiquidBalance - unpaidBillsDue - scheduledGoalContributions;
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

  /// Balance remaining after the first installment is paid today.
  final double postInstallmentBalance;

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
    required this.postInstallmentBalance,
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
  final monthlyInstallment = tenureMonths > 0
      ? totalCost / tenureMonths
      : totalCost;
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
    postInstallmentBalance: currentBalance - monthlyInstallment,
  );
}

/// Liquid balance that should count toward safe-to-spend.
///
/// When per-account balances are available and at least one account is
/// excluded, this sums the balances of the non-excluded accounts. Otherwise it
/// falls back to [dashboardTotalBalance]. The result is returned as-is and may
/// be negative; callers are responsible for clamping it to zero.
double adjustedLiquidBalance({
  required double dashboardTotalBalance,
  required Map<String, double>? accountBalances,
  required Set<String> excludedAccountIds,
}) {
  if (accountBalances == null ||
      accountBalances.isEmpty ||
      excludedAccountIds.isEmpty) {
    return dashboardTotalBalance;
  }

  var total = 0.0;
  for (final entry in accountBalances.entries) {
    if (!excludedAccountIds.contains(entry.key)) {
      total += entry.value;
    }
  }
  return total;
}
