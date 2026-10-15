import { describe, it, expect } from 'vitest';
import { calculatePurchaseAffordability } from './purchase-check';

describe('calculatePurchaseAffordability Engine (F16)', () => {
  const fixedNow = new Date('2026-10-15T12:00:00.000Z');

  it('verdict is AFFORDABLE when balance, bills, and threshold are safely met', () => {
    const result = calculatePurchaseAffordability({
      itemTitle: 'Noise Cancelling Headphones',
      amount: 5000,
      currentBalance: 50000,
      projectedMonthEndBalance: 45000,
      minimumThreshold: 2000,
      totalUpcomingBills: 12000,
      dailySurplus: 500,
      now: fixedNow,
    });

    expect(result.verdict).toBe('AFFORDABLE');
    expect(result.statusTitle).toBe('Safely Affordable');
    expect(result.postPurchaseBalance).toBe(45000);
    expect(result.cashAfterBills).toBe(33000);
    expect(result.postPurchaseMonthEndBalance).toBe(40000);
    expect(result.earliestSafeBuyDate).toBeNull();
  });

  it('verdict is NOT_RECOMMENDED when purchase causes immediate deficit', () => {
    const result = calculatePurchaseAffordability({
      itemTitle: 'Luxury Watch',
      amount: 60000,
      currentBalance: 50000,
      projectedMonthEndBalance: 40000,
      minimumThreshold: 2000,
      totalUpcomingBills: 5000,
      dailySurplus: 500,
      now: fixedNow,
    });

    expect(result.verdict).toBe('NOT_RECOMMENDED');
    expect(result.statusTitle).toBe('Insufficient Funds');
    expect(result.postPurchaseBalance).toBe(-10000);
    expect(result.daysUntilSafeBuy).toBe(34); // Deficit = 60000 + 5000 + 2000 - 50000 = 17000. 17000 / 500 = 34 days
    expect(result.earliestSafeBuyDate).toBe('2026-11-18');
  });

  it('verdict is NOT_RECOMMENDED when purchase prevents covering upcoming bills', () => {
    const result = calculatePurchaseAffordability({
      itemTitle: 'Gaming Console',
      amount: 25000,
      currentBalance: 30000,
      projectedMonthEndBalance: 20000,
      minimumThreshold: 5000,
      totalUpcomingBills: 10000,
      dailySurplus: 250,
      now: fixedNow,
    });

    expect(result.verdict).toBe('NOT_RECOMMENDED');
    expect(result.statusTitle).toBe('Unable to Cover Upcoming Bills');
    expect(result.cashAfterBills).toBe(-5000); // 5000 remaining - 10000 bills
    expect(result.daysUntilSafeBuy).toBe(40); // 25000 + 10000 + 5000 - 30000 = 10000. 10000 / 250 = 40 days
  });

  it('verdict is RISKY when balance drops below minimum safety threshold', () => {
    const result = calculatePurchaseAffordability({
      itemTitle: 'Desk Chair',
      amount: 8000,
      currentBalance: 12000,
      projectedMonthEndBalance: 15000,
      minimumThreshold: 5000,
      totalUpcomingBills: 1000,
      dailySurplus: 200,
      now: fixedNow,
    });

    expect(result.verdict).toBe('RISKY');
    expect(result.statusTitle).toBe('High Risk Purchase');
    expect(result.postPurchaseBalance).toBe(4000); // 12000 - 8000 = 4000 < 5000
    expect(result.cashAfterBills).toBe(3000); // 4000 - 1000 = 3000
    expect(result.daysUntilSafeBuy).toBe(10); // 8000 + 1000 + 5000 - 12000 = 2000. 2000 / 200 = 10 days
  });

  it('calculates savings goal delay accurately', () => {
    const result = calculatePurchaseAffordability({
      itemTitle: 'Smartphone',
      amount: 30000,
      currentBalance: 25000,
      projectedMonthEndBalance: 20000,
      minimumThreshold: 2000,
      totalUpcomingBills: 5000,
      dailySurplus: 1000,
      activeGoals: [
        { name: 'Emergency Fund', targetDate: new Date('2026-12-01T00:00:00.000Z') },
      ],
      now: fixedNow,
    });

    expect(result.goalImpacts).toHaveLength(1);
    expect(result.goalImpacts[0]?.goalName).toBe('Emergency Fund');
    expect(result.goalImpacts[0]?.delayDays).toBe(30); // 30000 / 1000 = 30 days
    expect(result.goalImpacts[0]?.delayedTargetDate).toBe('2026-12-31');
  });

  it('handles zero or negative daily surplus gracefully without infinite days', () => {
    const result = calculatePurchaseAffordability({
      itemTitle: 'Camera',
      amount: 15000,
      currentBalance: 10000,
      projectedMonthEndBalance: 8000,
      minimumThreshold: 2000,
      totalUpcomingBills: 3000,
      dailySurplus: 0,
      now: fixedNow,
    });

    expect(result.verdict).toBe('NOT_RECOMMENDED');
    expect(result.daysUntilSafeBuy).toBeNull();
    expect(result.earliestSafeBuyDate).toBeNull();
    expect(result.reasons).toContain('A safe purchase date cannot be estimated until you have a positive savings rate.');
  });
});

