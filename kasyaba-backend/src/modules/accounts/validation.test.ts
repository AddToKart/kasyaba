import { describe, it, expect } from 'vitest';
import { createAccountSchema, updateAccountSchema } from '../../modules/accounts/validation';

describe('Account validation schemas', () => {
  describe('createAccountSchema', () => {
    it('accepts valid account data', () => {
      const result = createAccountSchema.safeParse({
        name: 'Cash Wallet',
        type: 'cash',
        openingBalance: '1000.00',
        currencyCode: 'PHP',
      });
      expect(result.success).toBe(true);
    });

    it('applies defaults', () => {
      const result = createAccountSchema.safeParse({
        name: 'Test Account',
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.type).toBe('cash');
        expect(result.data.openingBalance).toBe('0');
        expect(result.data.currencyCode).toBe('PHP');
      }
    });

    it('rejects invalid amount format', () => {
      const result = createAccountSchema.safeParse({
        name: 'Test',
        openingBalance: 'abc',
      });
      expect(result.success).toBe(false);
    });

    it('rejects empty name', () => {
      const result = createAccountSchema.safeParse({
        name: '',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('updateAccountSchema', () => {
    it('accepts partial update', () => {
      const result = updateAccountSchema.safeParse({ name: 'New Name' });
      expect(result.success).toBe(true);
    });

    it('accepts empty object', () => {
      const result = updateAccountSchema.safeParse({});
      expect(result.success).toBe(true);
    });
  });
});
