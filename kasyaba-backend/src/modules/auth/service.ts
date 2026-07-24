import crypto from 'crypto';
import * as argon2 from 'argon2';
import { prisma } from '../../config/database';
import { signAccessToken, TokenPayload } from '../../middleware/auth';
import { AppError, ConflictError, NotFoundError, UnauthorizedError } from '../../lib/errors';
import { generateId } from '../../lib/id';
import { env } from '../../config/env';
import type { RegisterInput, LoginInput } from './validation';

function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function generateRefreshToken(): string {
  return crypto.randomBytes(48).toString('hex');
}

function getRefreshTokenExpiry(): Date {
  const expires = new Date();
  expires.setDate(expires.getDate() + env.REFRESH_TOKEN_TTL_DAYS);
  return expires;
}

export async function registerUser(input: RegisterInput) {
  const existing = await prisma.user.findUnique({ where: { email: input.email } });
  if (existing) {
    throw new ConflictError('Email already registered');
  }

  const passwordHash = await argon2.hash(input.password);
  const user = await prisma.user.create({
    data: {
      email: input.email,
      passwordHash,
      displayName: input.displayName || input.email.split('@')[0],
    },
  });

  return createSession(user.id, user.email);
}

export async function loginUser(input: LoginInput) {
  const user = await prisma.user.findUnique({ where: { email: input.email } });
  if (!user || !user.passwordHash) {
    throw new UnauthorizedError('Invalid email or password');
  }

  const valid = await argon2.verify(user.passwordHash, input.password);
  if (!valid) {
    throw new UnauthorizedError('Invalid email or password');
  }

  await prisma.user.update({
    where: { id: user.id },
    data: { lastLoginAt: new Date() },
  });

  return createSession(user.id, user.email);
}

export async function googleAuth(idToken: string) {
  if (!env.GOOGLE_WEB_CLIENT_ID) {
    throw new AppError(501, 'NOT_CONFIGURED', 'Google authentication is not configured');
  }

  const { OAuth2Client } = require('google-auth-library');
  const client = new OAuth2Client(env.GOOGLE_WEB_CLIENT_ID);
  const ticket = await client.verifyIdToken({
    idToken,
    audience: env.GOOGLE_WEB_CLIENT_ID,
  });
  const payload = ticket.getPayload();
  if (!payload || !payload.email) {
    throw new UnauthorizedError('Invalid Google token');
  }

  const email = payload.email.toLowerCase();
  const googleSubject = payload.sub;

  // Find or create user
  let user = await prisma.user.findFirst({
    where: {
      OR: [{ email }, { googleSubject }],
    },
  });

  if (user) {
    // Link Google account if not already linked
    if (!user.googleSubject) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { googleSubject, lastLoginAt: new Date() },
      });
    } else {
      await prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      });
    }
  } else {
    user = await prisma.user.create({
      data: {
        email,
        googleSubject,
        displayName: payload.name || email.split('@')[0],
        avatarUrl: payload.picture,
      },
    });
  }

  return createSession(user.id, user.email);
}

export async function refreshSession(refreshToken: string) {
  const tokenHash = hashToken(refreshToken);
  const session = await prisma.authSession.findFirst({
    where: {
      refreshTokenHash: tokenHash,
      revokedAt: null,
      expiresAt: { gt: new Date() },
    },
    include: { user: true },
  });

  if (!session) {
    throw new UnauthorizedError('Invalid or expired refresh token');
  }

  // Rotate: revoke old session, create new one
  await prisma.authSession.update({
    where: { id: session.id },
    data: { revokedAt: new Date() },
  });

  return createSession(session.user.id, session.user.email);
}

export async function logoutUser(refreshToken: string) {
  const tokenHash = hashToken(refreshToken);
  await prisma.authSession.updateMany({
    where: {
      refreshTokenHash: tokenHash,
      revokedAt: null,
    },
    data: { revokedAt: new Date() },
  });
}

export async function logoutAllSessions(userId: string) {
  await prisma.authSession.updateMany({
    where: {
      userId,
      revokedAt: null,
    },
    data: { revokedAt: new Date() },
  });
}

export async function getCurrentUser(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
      timezone: true,
      currencyCode: true,
      minimumBalanceThreshold: true,
      createdAt: true,
      lastLoginAt: true,
    },
  });
  if (!user) throw new NotFoundError('User not found');
  return user;
}

async function createSession(userId: string, email: string) {
  const refreshToken = generateRefreshToken();
  const tokenHash = hashToken(refreshToken);

  const session = await prisma.authSession.create({
    data: {
      userId,
      refreshTokenHash: tokenHash,
      expiresAt: getRefreshTokenExpiry(),
    },
  });

  const accessToken = await signAccessToken({ sub: userId, email });

  return {
    accessToken,
    refreshToken,
    expiresIn: env.ACCESS_TOKEN_TTL_MINUTES * 60,
    sessionId: session.id,
  };
}
