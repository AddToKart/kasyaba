import { describe, it, expect } from 'vitest';
import { registerSchema, loginSchema, googleAuthSchema, refreshSchema } from '../../modules/auth/validation';

describe('Auth validation schemas', () => {
  describe('registerSchema', () => {
    it('accepts valid registration data', () => {
      const result = registerSchema.safeParse({
        email: 'Test@Example.com',
        password: 'password123',
        displayName: 'Test User',
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.email).toBe('test@example.com'); // lowercased
        expect(result.data.password).toBe('password123');
        expect(result.data.displayName).toBe('Test User');
      }
    });

    it('rejects short password', () => {
      const result = registerSchema.safeParse({
        email: 'test@example.com',
        password: 'short',
      });
      expect(result.success).toBe(false);
    });

    it('rejects invalid email', () => {
      const result = registerSchema.safeParse({
        email: 'not-an-email',
        password: 'password123',
      });
      expect(result.success).toBe(false);
    });

    it('accepts registration without displayName', () => {
      const result = registerSchema.safeParse({
        email: 'test@example.com',
        password: 'password123',
      });
      expect(result.success).toBe(true);
    });
  });

  describe('loginSchema', () => {
    it('accepts valid login data', () => {
      const result = loginSchema.safeParse({
        email: 'Test@Example.com',
        password: 'mypassword',
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.email).toBe('test@example.com');
      }
    });

    it('rejects empty password', () => {
      const result = loginSchema.safeParse({
        email: 'test@example.com',
        password: '',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('googleAuthSchema', () => {
    it('accepts valid Google ID token', () => {
      const result = googleAuthSchema.safeParse({ idToken: 'some-token' });
      expect(result.success).toBe(true);
    });

    it('rejects empty token', () => {
      const result = googleAuthSchema.safeParse({ idToken: '' });
      expect(result.success).toBe(false);
    });
  });

  describe('refreshSchema', () => {
    it('accepts valid refresh token', () => {
      const result = refreshSchema.safeParse({ refreshToken: 'some-token' });
      expect(result.success).toBe(true);
    });

    it('rejects empty token', () => {
      const result = refreshSchema.safeParse({ refreshToken: '' });
      expect(result.success).toBe(false);
    });
  });
});
