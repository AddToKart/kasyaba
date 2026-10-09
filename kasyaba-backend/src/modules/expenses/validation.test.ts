import { describe, it, expect } from 'vitest';
import { createExpenseSchema, expenseQuerySchema } from '../../modules/expenses/validation';

describe('Expense validation schemas', () => {
  describe('createExpenseSchema', () => {
    it('accepts valid expense data', () => {
      const result = createExpenseSchema.safeParse({
        accountId: '00000000-0000-0000-0000-000000000001',
        categoryId: '00000000-0000-0000-0000-000000000002',
        amount: '250.75',
        description: 'Lunch at restaurant',
        spentAt: '2024-01-15',
      });
      expect(result.success).toBe(true);
    });

    it('rejects empty description', () => {
      const result = createExpenseSchema.safeParse({
        accountId: '00000000-0000-0000-0000-000000000001',
        categoryId: '00000000-0000-0000-0000-000000000002',
        amount: '100',
        description: '',
        spentAt: '2024-01-15',
      });
      expect(result.success).toBe(false);
    });

    it('accepts a future scheduled expense date', () => {
      const result = createExpenseSchema.safeParse({
        accountId: '00000000-0000-0000-0000-000000000001',
        categoryId: '00000000-0000-0000-0000-000000000002',
        amount: '250.75',
        description: 'Planned trip',
        spentAt: '2099-12-31',
      });
      expect(result.success).toBe(true);
    });

    it('rejects an impossible date', () => {
      const result = createExpenseSchema.safeParse({
        accountId: '00000000-0000-0000-0000-000000000001',
        categoryId: '00000000-0000-0000-0000-000000000002',
        amount: '250.75',
        description: 'Invalid date',
        spentAt: '2024-02-30',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('expenseQuerySchema', () => {
    it('accepts search parameter', () => {
      const result = expenseQuerySchema.safeParse({
        search: 'lunch',
        page: '1',
        limit: '50',
      });
      expect(result.success).toBe(true);
    });

    it('enforces max limit', () => {
      const result = expenseQuerySchema.safeParse({ limit: '200' });
      expect(result.success).toBe(false);
    });

    it('rejects a reversed date range', () => {
      const result = expenseQuerySchema.safeParse({
        from: '2026-08-29',
        to: '2026-08-28',
      });
      expect(result.success).toBe(false);
    });
  });
});
