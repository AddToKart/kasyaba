import { describe, it, expect } from 'vitest';
import { budgetStatusSchema } from './budgets/validation';
import { createGoalSchema } from './goals/validation';
import { createBillTemplateSchema } from './bills/validation';

describe('Budget validation', () => {
  describe('budgetStatusSchema', () => {
    it('accepts valid month format', () => {
      const result = budgetStatusSchema.safeParse({ month: '2024-01' });
      expect(result.success).toBe(true);
    });

    it('rejects invalid month format', () => {
      const result = budgetStatusSchema.safeParse({ month: '2024/01' });
      expect(result.success).toBe(false);
    });
  });
});

describe('Goal validation', () => {
  describe('createGoalSchema', () => {
    it('accepts valid goal data', () => {
      const result = createGoalSchema.safeParse({
        name: 'Emergency Fund',
        targetAmount: '50000.00',
        targetDate: '2024-12-31',
      });
      expect(result.success).toBe(true);
    });

    it('accepts goal without target date', () => {
      const result = createGoalSchema.safeParse({
        name: 'New Laptop',
        targetAmount: '75000.00',
      });
      expect(result.success).toBe(true);
    });

    it('rejects empty name', () => {
      const result = createGoalSchema.safeParse({
        name: '',
        targetAmount: '1000',
      });
      expect(result.success).toBe(false);
    });
  });
});

describe('Bill template validation', () => {
  describe('createBillTemplateSchema', () => {
    it('accepts monthly bill', () => {
      const result = createBillTemplateSchema.safeParse({
        name: 'Rent',
        defaultAmount: '15000.00',
        recurrence: 'monthly',
        dayOfMonth: 1,
        startsOn: '2024-01-01',
      });
      expect(result.success).toBe(true);
    });

    it('accepts one-time bill without recurrence', () => {
      const result = createBillTemplateSchema.safeParse({
        name: 'One-time bill',
        defaultAmount: '500.00',
        recurrence: 'none',
        startsOn: '2024-06-15',
      });
      expect(result.success).toBe(true);
    });

    it('rejects invalid dayOfMonth', () => {
      const result = createBillTemplateSchema.safeParse({
        name: 'Test',
        defaultAmount: '100',
        dayOfMonth: 32,
        startsOn: '2024-01-01',
      });
      expect(result.success).toBe(false);
    });
  });
});
