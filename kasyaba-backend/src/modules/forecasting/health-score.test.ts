import { describe, it, expect } from 'vitest';
import Decimal from 'decimal.js';

// Copy of the health score computation for testing
type HealthGrade = 'Excellent' | 'Good' | 'Fair' | 'Needs Attention';

interface HealthInput {
  incomeMTD: Decimal;
  expensesMTD: Decimal;
  savingsMTD: Decimal;
  projectedMonthEndExpenses: Decimal;
  actualBalance: Decimal;
  predictedMonthEndBalance: Decimal;
}

function computeHealthScore(input: HealthInput): { score: number; grade: HealthGrade } {
  const { incomeMTD, expensesMTD, savingsMTD } = input;

  // --- Savings score (30%) ---
  let savingsScore = 0;
  const savingsRate = incomeMTD.gt(0) ? Number(savingsMTD.div(incomeMTD)) : 0;
  if (savingsRate >= 0.20) savingsScore = 100;
  else if (savingsRate >= 0.10) savingsScore = 70 + (savingsRate - 0.10) / 0.10 * 29;
  else if (savingsRate > 0) savingsScore = 30 + (savingsRate / 0.10) * 39;
  else savingsScore = 0;

  // --- Budget score (30%) ---
  let budgetScore = 0;
  const budgetTotal = Number(input.projectedMonthEndExpenses);
  const incomeTotal = Number(incomeMTD);
  const budgetRatio = incomeTotal > 0 ? budgetTotal / incomeTotal : 1;

  if (budgetRatio <= 0.90) budgetScore = 100;
  else if (budgetRatio <= 1.00) budgetScore = 70 + (1 - budgetRatio) / 0.10 * 29;
  else if (budgetRatio <= 1.15) budgetScore = 30 + (1.15 - budgetRatio) / 0.15 * 39;
  else budgetScore = Math.max(0, 30 - (budgetRatio - 1.15) / 0.15 * 30);

  // --- Bill reliability (20%) ---
  const billScore = 70; // Default for test

  // --- Balance resilience (20%) ---
  let resilienceScore = 50;
  const projectedBalance = Number(input.predictedMonthEndBalance);
  if (projectedBalance > 0) {
    resilienceScore = Math.min(100, 50 + (projectedBalance / (incomeTotal || 1)) * 100);
  } else {
    resilienceScore = Math.max(0, 50 + (projectedBalance / (incomeTotal || 1)) * 50);
  }

  const totalScore = Math.round(
    savingsScore * 0.30 + budgetScore * 0.30 + billScore * 0.20 + resilienceScore * 0.20
  );

  let grade: HealthGrade;
  if (totalScore >= 85) grade = 'Excellent';
  else if (totalScore >= 70) grade = 'Good';
  else if (totalScore >= 50) grade = 'Fair';
  else grade = 'Needs Attention';

  return { score: totalScore, grade };
}

describe('Financial Health Score', () => {
  // Scenario 1: Healthy finances - saving 20%+, budget under 90%
  it('should rate Excellent for healthy finances', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal('50000'),
      expensesMTD: new Decimal('25000'),
      savingsMTD: new Decimal('10000'), // 20% savings rate
      projectedMonthEndExpenses: new Decimal('40000'), // 80% of income
      actualBalance: new Decimal('50000'),
      predictedMonthEndBalance: new Decimal('20000'),
    });
    expect(result.score).toBeGreaterThanOrEqual(85);
    expect(result.grade).toBe('Excellent');
  });

  // Scenario 2: No savings
  it('should penalize zero savings', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal('30000'),
      expensesMTD: new Decimal('30000'),
      savingsMTD: new Decimal('0'),
      projectedMonthEndExpenses: new Decimal('30000'),
      actualBalance: new Decimal('10000'),
      predictedMonthEndBalance: new Decimal('5000'),
    });
    expect(result.score).toBeLessThan(70);
  });

  // Scenario 3: Over budget (>100%)
  it('should penalize exceeding budget', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal('30000'),
      expensesMTD: new Decimal('25000'),
      savingsMTD: new Decimal('1000'),
      projectedMonthEndExpenses: new Decimal('35000'), // 117% of income
      actualBalance: new Decimal('5000'),
      predictedMonthEndBalance: new Decimal('-2000'),
    });
    expect(result.score).toBeLessThan(50);
    expect(result.grade).toBe('Needs Attention');
  });

  // Scenario 4: Moderate saver (15% rate)
  it('should rate Good for moderate saver', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal('40000'),
      expensesMTD: new Decimal('28000'),
      savingsMTD: new Decimal('6000'), // 15% savings rate
      projectedMonthEndExpenses: new Decimal('36000'), // 90%
      actualBalance: new Decimal('30000'),
      predictedMonthEndBalance: new Decimal('10000'),
    });
    expect(result.score).toBeGreaterThanOrEqual(70);
    expect(result.score).toBeLessThan(85);
    expect(result.grade).toBe('Good');
  });

  // Scenario 5: Negative balance
  it('should penalize negative projected balance', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal('20000'),
      expensesMTD: new Decimal('22000'),
      savingsMTD: new Decimal('0'),
      projectedMonthEndExpenses: new Decimal('25000'),
      actualBalance: new Decimal('500'),
      predictedMonthEndBalance: new Decimal('-2000'),
    });
    expect(result.score).toBeLessThan(50);
  });

  // Scenario 5: User completing a goal (no savings needed extra)
  it('should rate well for balanced finances', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal('60000'),
      expensesMTD: new Decimal('30000'),
      savingsMTD: new Decimal('15000'), // 25% rate
      projectedMonthEndExpenses: new Decimal('42000'), // 70% of income
      actualBalance: new Decimal('100000'),
      predictedMonthEndBalance: new Decimal('50000'),
    });
    expect(result.score).toBeGreaterThanOrEqual(85);
    expect(result.grade).toBe('Excellent');
  });

  // Scenario 6: Zero income edge case
  it('should handle zero income gracefully', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal('0'),
      expensesMTD: new Decimal('1000'),
      savingsMTD: new Decimal('0'),
      projectedMonthEndExpenses: new Decimal('1000'),
      actualBalance: new Decimal('0'),
      predictedMonthEndBalance: new Decimal('0'),
    });
    expect(typeof result.score).toBe('number');
    expect(result.grade).toBeDefined();
  });
});
