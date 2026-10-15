import Decimal from 'decimal.js';
import { prisma } from '../../config/database';
import { toDecimalOrZero } from '../../lib/decimal';

export interface DailySurplusContext {
  salaryAmount?: Decimal | number | string | null;
  projectedMonthEndExpenses?: Decimal | number | string | null;
  expensesMTD?: Decimal | number | string | null;
  incomeMTD?: Decimal | number | string | null;
}

/**
 * Calculates a canonical daily net surplus rate for a user.
 * Blends configured salary with monthly expenses, falling back to
 * trailing 30-day cashflow or MTD cashflow when unconfigured.
 */
export async function calculateDailySurplus(
  userId: string,
  context?: DailySurplusContext,
): Promise<Decimal> {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 86400000);

  let salaryAmount = context?.salaryAmount !== undefined
    ? toDecimalOrZero(context.salaryAmount)
    : null;

  if (salaryAmount === null) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { salaryAmount: true },
    });
    salaryAmount = toDecimalOrZero(user?.salaryAmount);
  }

  const [trailingIncomeAgg, trailingExpenseAgg] = await Promise.all([
    prisma.incomeEntry.aggregate({
      where: { userId, status: { in: ['posted', 'planned'] }, receivedAt: { gte: thirtyDaysAgo, lte: now } },
      _sum: { amount: true },
    }),
    prisma.expenseEntry.aggregate({
      where: { userId, status: { in: ['posted', 'planned'] }, spentAt: { gte: thirtyDaysAgo, lte: now } },
      _sum: { amount: true },
    }),
  ]);

  const trailingIncome = toDecimalOrZero(trailingIncomeAgg._sum.amount);
  const trailingExpenses = toDecimalOrZero(trailingExpenseAgg._sum.amount);

  // 1. If salary is configured, blend with monthly expense baseline (preferring projected or trailing 30d)
  if (salaryAmount.gt(0)) {
    const monthlyExpenses = context?.projectedMonthEndExpenses !== undefined
      ? toDecimalOrZero(context.projectedMonthEndExpenses)
      : (trailingExpenses.gt(0) ? trailingExpenses : toDecimalOrZero(context?.expensesMTD));
    const monthlySurplus = salaryAmount.minus(monthlyExpenses);
    if (monthlySurplus.gt(0)) {
      return monthlySurplus.div(30);
    }
  }

  // 2. Fallback to trailing 30-day observed net cashflow
  const net30 = trailingIncome.minus(trailingExpenses);
  if (net30.gt(0)) {
    return net30.div(30);
  }

  // 3. Fallback to MTD cashflow if available in context and positive
  if (context?.incomeMTD !== undefined && context?.expensesMTD !== undefined) {
    const mtdNet = toDecimalOrZero(context.incomeMTD).minus(toDecimalOrZero(context.expensesMTD));
    if (mtdNet.gt(0)) {
      return mtdNet.div(30);
    }
  }

  return new Decimal(0);
}

