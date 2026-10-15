import { describe, it, expect } from 'vitest';
import Decimal from 'decimal.js';
import { computeProjectedIncome, computeDataConfidence } from './service';

describe('Forecasting Onboarding Stability & Confidence (F7)', () => {
  describe('computeProjectedIncome', () => {
    it('uses weighted 3-month average when 3 or more history months exist', () => {
      const history = [new Decimal(60000), new Decimal(55000), new Decimal(50000)];
      const mtd = new Decimal(20000);
      const salary = new Decimal(50000);

      const result = computeProjectedIncome(history, mtd, salary);
      // 60000*0.5 + 55000*0.3 + 50000*0.2 = 30000 + 16500 + 10000 = 56500
      expect(result.toNumber()).toBe(56500);
    });

    it('does not wildly extrapolate single payday across remaining days for month 2 onboarding', () => {
      // Month 2 user paid ₱30,000 on day 5 with salary ₱60,000 and 1 prior history month of ₱60,000
      const history = [new Decimal(60000)];
      const mtd = new Decimal(30000);
      const salary = new Decimal(60000);

      const result = computeProjectedIncome(history, mtd, salary);
      // Under old bug: 30000 / 5 * 31 = 186000
      // With F7 fix: bounded by max(salary, historyAvg, mtd) = 60000
      expect(result.toNumber()).toBe(60000);
    });

    it('uses salaryAmount as baseline for month 1 onboarding when no history exists', () => {
      const history: Decimal[] = [];
      const mtd = new Decimal(25000); // partial payday
      const salary = new Decimal(50000);

      const result = computeProjectedIncome(history, mtd, salary);
      expect(result.toNumber()).toBe(50000);
    });

    it('allows mtd to exceed salary if user earned bonuses or freelance inflows', () => {
      const history: Decimal[] = [];
      const mtd = new Decimal(75000); // salary + big bonus
      const salary = new Decimal(50000);

      const result = computeProjectedIncome(history, mtd, salary);
      expect(result.toNumber()).toBe(75000);
    });

    it('falls back safely to mtd if no salary and no history (clean onboarding)', () => {
      const history: Decimal[] = [];
      const mtd = new Decimal(15000);
      const salary = new Decimal(0);

      const result = computeProjectedIncome(history, mtd, salary);
      expect(result.toNumber()).toBe(15000);
    });
  });

  describe('computeDataConfidence', () => {
    it('returns high confidence only when both expense and income history have 3+ months', () => {
      expect(computeDataConfidence(3, 3, 10, true)).toBe('high');
      expect(computeDataConfidence(3, 3, 10, false)).toBe('high');
    });

    it('returns medium confidence during onboarding if partial history exists', () => {
      // Month 2 user: 1 month of expense and 1 month of income history
      expect(computeDataConfidence(1, 1, 10, false)).toBe('medium');
      // User with configured salary and at least 30 days of expense tracking
      expect(computeDataConfidence(0, 0, 30, true)).toBe('medium');
    });

    it('returns low confidence for new users with no history and no salary', () => {
      expect(computeDataConfidence(0, 0, 5, false)).toBe('low');
    });
  });
});

