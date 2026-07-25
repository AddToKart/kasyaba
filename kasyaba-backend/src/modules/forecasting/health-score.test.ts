import { describe, it, expect } from 'vitest';
import Decimal from 'decimal.js';

// Import the actual health score computation — tested as a standalone pure function.
// We re-export it from the service module. The service.ts internally uses it
// as a private function; we test its logic here via a co-located export.
//
// NOTE: The canonical implementation lives in forecasting/service.ts inside computeSnapshot().
// If the formula changes, update the import below.
import { computeHealthScore } from './service';

type HealthInput = {
  incomeMTD: Decimal;
  expensesMTD: Decimal;
  savingsMTD: Decimal;
  projectedMonthEndExpenses: Decimal;
  actualBalance: Decimal;
  predictedMonthEndBalance: Decimal;
  billPaymentRate: number;
};

describe('Financial Health Score', () => {
  const baseInput: HealthInput = {
    incomeMTD: new Decimal(50000),
    expensesMTD: new Decimal(30000),
    savingsMTD: new Decimal(10000),
    projectedMonthEndExpenses: new Decimal(32000),
    actualBalance: new Decimal(25000),
    predictedMonthEndBalance: new Decimal(18000),
    billPaymentRate: 1, // perfect payment history
  };

  it('savings rate 20%+ gives max savings score', () => {
    const result = computeHealthScore({ ...baseInput, savingsMTD: new Decimal(12000) });
    expect(result.score).toBeGreaterThanOrEqual(70);
  });

  it('no savings gives floor savings score', () => {
    const result = computeHealthScore({ ...baseInput, savingsMTD: new Decimal(0) });
    // savings = 0, so ~0 * 0.30 = 0 for that component, rest weighted normally
    expect(result.score).toBeLessThan(85);
  });

  it('budget well under income gives high budget score', () => {
    const result = computeHealthScore({
      ...baseInput,
      projectedMonthEndExpenses: new Decimal(20000),
    });
    expect(result.score).toBeGreaterThanOrEqual(80);
  });

  it('predicted deficit reduces score', () => {
    const result = computeHealthScore({
      ...baseInput,
      predictedMonthEndBalance: new Decimal(-5000),
    });
    expect(result.score).toBeLessThan(90);
  });

  it('low bill payment rate reduces score', () => {
    const result = computeHealthScore({
      ...baseInput,
      savingsMTD: new Decimal(0),
      billPaymentRate: 0.4,
    });
    // bill reliability component should be significantly lower
    expect(result.score).toBeLessThan(70);
  });

  it('returns Excellent grade for strong finances', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal(100000),
      expensesMTD: new Decimal(30000),
      savingsMTD: new Decimal(30000),
      projectedMonthEndExpenses: new Decimal(35000),
      actualBalance: new Decimal(80000),
      predictedMonthEndBalance: new Decimal(75000),
      billPaymentRate: 1,
    });
    expect(result.grade).toBe('Excellent');
    expect(result.score).toBeGreaterThanOrEqual(85);
  });

  it('returns Needs Attention for poor finances', () => {
    const result = computeHealthScore({
      incomeMTD: new Decimal(10000),
      expensesMTD: new Decimal(12000),
      savingsMTD: new Decimal(0),
      projectedMonthEndExpenses: new Decimal(15000),
      actualBalance: new Decimal(500),
      predictedMonthEndBalance: new Decimal(-2000),
      billPaymentRate: 0.3,
    });
    expect(result.grade).toBe('Needs Attention');
    expect(result.score).toBeLessThan(50);
  });
});
