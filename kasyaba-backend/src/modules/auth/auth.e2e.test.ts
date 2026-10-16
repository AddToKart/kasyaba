import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import { createApp } from '../../app';
import * as authService from './service';
import { signAccessToken } from '../../middleware/auth';
import { ConflictError, UnauthorizedError, NotFoundError, AppError } from '../../lib/errors';

vi.mock('./service');

describe('Auth Endpoints E2E Integration Tests', () => {
  const app = createApp();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('POST /api/v1/auth/register', () => {
    it('successfully registers a user with valid credentials', async () => {
      vi.mocked(authService.registerUser).mockResolvedValueOnce({
        accessToken: 'access-token-123',
        refreshToken: 'refresh-token-123',
        expiresIn: 900,
        sessionId: 'session-123',
        user: { id: 'user-123', email: 'test@kasyaba.app' },
      });

      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'test@kasyaba.app',
          password: 'Password123!',
          displayName: 'Test User',
        });

      expect(res.status).toBe(201);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.accessToken).toBe('access-token-123');
      expect(res.body.data.user.email).toBe('test@kasyaba.app');
    });

    it('rejects registration with invalid email format', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'not-an-email',
          password: 'Password123!',
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('rejects registration with password shorter than 8 characters', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'test@kasyaba.app',
          password: 'short',
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('returns 409 Conflict if email is already registered', async () => {
      vi.mocked(authService.registerUser).mockRejectedValueOnce(
        new ConflictError('Email already registered')
      );

      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'existing@kasyaba.app',
          password: 'Password123!',
        });

      expect(res.status).toBe(409);
      expect(res.body.error.code).toBe('CONFLICT');
    });
  });

  describe('POST /api/v1/auth/login', () => {
    it('successfully logs in with correct credentials', async () => {
      vi.mocked(authService.loginUser).mockResolvedValueOnce({
        accessToken: 'access-token-valid',
        refreshToken: 'refresh-token-valid',
        expiresIn: 900,
        sessionId: 'session-123',
        user: { id: 'user-123', email: 'test@kasyaba.app' },
      });

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'test@kasyaba.app',
          password: 'Password123!',
        });

      expect(res.status).toBe(200);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.accessToken).toBe('access-token-valid');
    });

    it('returns 401 Unauthorized for wrong credentials', async () => {
      vi.mocked(authService.loginUser).mockRejectedValueOnce(
        new UnauthorizedError('Invalid email or password')
      );

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'test@kasyaba.app',
          password: 'WrongPassword!',
        });

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });
  });

  describe('POST /api/v1/auth/google', () => {
    it('rejects Google auth with missing idToken', async () => {
      const res = await request(app)
        .post('/api/v1/auth/google')
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('rejects Google auth with empty idToken', async () => {
      const res = await request(app)
        .post('/api/v1/auth/google')
        .send({ idToken: '' });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('successfully authenticates with valid Google idToken', async () => {
      vi.mocked(authService.googleAuth).mockResolvedValueOnce({
        accessToken: 'access-google-token',
        refreshToken: 'refresh-google-token',
        expiresIn: 900,
        sessionId: 'session-google-123',
        user: { id: 'user-google-123', email: 'googleuser@kasyaba.app' },
      });

      const res = await request(app)
        .post('/api/v1/auth/google')
        .send({ idToken: 'valid-google-id-token' });

      expect(res.status).toBe(200);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.accessToken).toBe('access-google-token');
      expect(res.body.data.user.email).toBe('googleuser@kasyaba.app');
    });

    it('returns 401 when Google token is invalid or unverified', async () => {
      vi.mocked(authService.googleAuth).mockRejectedValueOnce(
        new UnauthorizedError('Invalid Google token')
      );

      const res = await request(app)
        .post('/api/v1/auth/google')
        .send({ idToken: 'invalid-token' });

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('returns 501 when Google auth is not configured on the server', async () => {
      vi.mocked(authService.googleAuth).mockRejectedValueOnce(
        new AppError(501, 'NOT_CONFIGURED', 'Google authentication is not configured')
      );

      const res = await request(app)
        .post('/api/v1/auth/google')
        .send({ idToken: 'any-token' });

      expect(res.status).toBe(501);
      expect(res.body.error.code).toBe('NOT_CONFIGURED');
    });
  });

  describe('Protected Routes & JWT Authentication', () => {
    it('blocks /api/v1/auth/me when no Authorization header is provided', async () => {
      const res = await request(app).get('/api/v1/auth/me');
      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('blocks /api/v1/auth/me with an invalid JWT token', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer invalid-token-string');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('allows access to /api/v1/auth/me with a valid JWT token', async () => {
      const validToken = await signAccessToken({ sub: 'user-123', email: 'test@kasyaba.app' });
      vi.mocked(authService.getCurrentUser).mockResolvedValueOnce({
        id: 'user-123',
        email: 'test@kasyaba.app',
        displayName: 'Test User',
        avatarUrl: null,
        timezone: 'Asia/Manila',
        currencyCode: 'PHP',
        minimumBalanceThreshold: '0' as never,
        salaryAmount: '35000' as never,
        paydayFrequency: 'semi-monthly',
        paydaySchedule: '15th & 30th',
        createdAt: new Date(),
        lastLoginAt: new Date(),
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${validToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.id).toBe('user-123');
      expect(res.body.data.salaryAmount).toBe('35000');
    });
  });

  describe('Token Refresh & Session Revocation', () => {
    it('successfully refreshes token with valid refresh token', async () => {
      vi.mocked(authService.refreshSession).mockResolvedValueOnce({
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        expiresIn: 900,
        sessionId: 'session-new',
        user: { id: 'user-123', email: 'test@kasyaba.app' },
      });

      const res = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: 'valid-refresh-token' });

      expect(res.status).toBe(200);
      expect(res.body.data.accessToken).toBe('new-access-token');
    });

    it('successfully logs out and revokes refresh token', async () => {
      const validToken = await signAccessToken({ sub: 'user-123', email: 'test@kasyaba.app' });
      vi.mocked(authService.logoutUser).mockResolvedValueOnce();

      const res = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ refreshToken: 'refresh-token-to-revoke' });

      expect(res.status).toBe(204);
      expect(authService.logoutUser).toHaveBeenCalledWith('user-123', 'refresh-token-to-revoke');
    });
  });

  describe('Google Play Mandated Account Deletion & Export', () => {
    it('successfully deletes account on DELETE /api/v1/auth/me', async () => {
      const validToken = await signAccessToken({ sub: 'user-123', email: 'test@kasyaba.app' });
      vi.mocked(authService.deleteAccount).mockResolvedValueOnce();

      const res = await request(app)
        .delete('/api/v1/auth/me')
        .set('Authorization', `Bearer ${validToken}`);

      expect(res.status).toBe(204);
      expect(authService.deleteAccount).toHaveBeenCalledWith('user-123', undefined);
    });

    it('forwards the confirmation password to the deletion service', async () => {
      const validToken = await signAccessToken({ sub: 'user-123', email: 'test@kasyaba.app' });
      vi.mocked(authService.deleteAccount).mockResolvedValueOnce();

      const res = await request(app)
        .delete('/api/v1/auth/me')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ password: 'Password123!' });

      expect(res.status).toBe(204);
      expect(authService.deleteAccount).toHaveBeenCalledWith('user-123', 'Password123!');
    });

    it('rejects an overlong confirmation password before reaching the service', async () => {
      const validToken = await signAccessToken({ sub: 'user-123', email: 'test@kasyaba.app' });

      const res = await request(app)
        .delete('/api/v1/auth/me')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ password: 'x'.repeat(129) });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
      expect(authService.deleteAccount).not.toHaveBeenCalled();
    });

    it('successfully exports user data on GET /api/v1/auth/export', async () => {
      const validToken = await signAccessToken({ sub: 'user-123', email: 'test@kasyaba.app' });
      vi.mocked(authService.exportUserData).mockResolvedValueOnce({
        exportedAt: new Date().toISOString(),
        user: { id: 'user-123', email: 'test@kasyaba.app' } as never,
      });

      const res = await request(app)
        .get('/api/v1/auth/export')
        .set('Authorization', `Bearer ${validToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.exportedAt).toBeDefined();
      expect(res.body.data.user.email).toBe('test@kasyaba.app');
    });

    it('successfully restores user data on POST /api/v1/auth/restore', async () => {
      const validToken = await signAccessToken({ sub: 'user-123', email: 'test@kasyaba.app' });
      vi.mocked(authService.restoreUserData).mockResolvedValueOnce({
        restoredAt: new Date().toISOString(),
        counts: {
          accounts: 2,
          expenses: 5,
          incomes: 1,
          transfers: 1,
          categories: 3,
          goals: 1,
          budgets: 1,
          bills: 1,
        },
      });

      const res = await request(app)
        .post('/api/v1/auth/restore')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          exportedAt: new Date().toISOString(),
          user: {
            salaryAmount: '45000',
            financialAccounts: [{ id: 'a1', name: 'BDO' }],
          },
        });

      expect(res.status).toBe(200);
      expect(res.body.data.restoredAt).toBeDefined();
      expect(res.body.data.counts.accounts).toBe(2);
      expect(res.body.data.counts.expenses).toBe(5);
    });
  });

  describe('Public Legal & Health Check Routes', () => {
    it('serves Privacy Policy page at /privacy', async () => {
      const res = await request(app).get('/privacy');
      expect(res.status).toBe(200);
      expect(res.text).toContain('Privacy Policy');
      expect(res.text).toContain('KASYABA');
    });

    it('serves Account Deletion instructions at /account-deletion', async () => {
      const res = await request(app).get('/account-deletion');
      expect(res.status).toBe(200);
      expect(res.text).toContain('Delete Your KASYABA Account');
    });

    it('returns ok on /health/live', async () => {
      const res = await request(app).get('/health/live');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('ok');
    });
  });
});
