import { describe, it, expect } from 'vitest';
import { createIncomeSchema, updateIncomeSchema, incomeQuerySchema } from '../../modules/income/validation';

describe('Income validation schemas', () => {
  describe('createIncomeSchema', () => {
    it('accepts valid income data', () => {
      const result = createIncomeSchema.safeParse({
        accountId: '00000000-0000-0000-0000-000000000001',
        amount: '15000.00',
        source: 'Salary',
        receivedAt: '2024-01-15',
      });
      expect(result.success).toBe(true);
    });

    it('rejects invalid amount', () => {
      const result = createIncomeSchema.safeParse({
        accountId: '00000000-0000-0000-0000-000000000001',
        amount: '-50',
        source: 'Gift',
        receivedAt: '2024-01-15',
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid UUID', () => {
      const result = createIncomeSchema.safeParse({
        accountId: 'not-a-uuid',
        amount: '100',
        source: 'Test',
        receivedAt: '2024-01-15',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('incomeQuerySchema', () => {
    it('applies defaults for pagination', () => {
      const result = incomeQuerySchema.safeParse({});
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.page).toBe(1);
        expect(result.data.limit).toBe(20);
      }
    });

    it('accepts date filters', () => {
      const result = incomeQuerySchema.safeParse({
        from: '2024-01-01',
        to: '2024-01-31',
        source: 'Salary',
        page: '2',
        limit: '10',
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.page).toBe(2);
        expect(result.data.limit).toBe(10);
      }
    });
  });
});
