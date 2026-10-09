import crypto from "crypto";
import * as argon2 from "argon2";
import { OAuth2Client } from "google-auth-library";
import { prisma } from "../../config/database";
import { signAccessToken } from "../../middleware/auth";
import {
  AppError,
  ConflictError,
  NotFoundError,
  UnauthorizedError,
  ValidationError,
} from "../../lib/errors";
import { env } from "../../config/env";
import { Prisma } from "@prisma/client";
import type {
  RegisterInput,
  LoginInput,
  UpdateProfileInput,
} from "./validation";

function hashToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function generateRefreshToken(): string {
  return crypto.randomBytes(48).toString("hex");
}

function getRefreshTokenExpiry(): Date {
  const expires = new Date();
  expires.setDate(expires.getDate() + env.REFRESH_TOKEN_TTL_DAYS);
  return expires;
}

export async function registerUser(input: RegisterInput) {
  const existing = await prisma.user.findUnique({
    where: { email: input.email },
  });
  if (existing) {
    throw new ConflictError("Email already registered");
  }

  const passwordHash = await argon2.hash(input.password);
  const user = await prisma.user.create({
    data: {
      email: input.email,
      passwordHash,
      displayName: input.displayName || input.email.split("@")[0],
    },
  });

  return createSession(user.id, user.email, true);
}

// A valid Argon2id hash used only to equalize login timing when the email is
// unknown, so response latency cannot be used to enumerate accounts.
const DUMMY_PASSWORD_HASH =
  "$argon2id$v=19$m=65536,t=3,p=4$GKmewFZOWrSFYExcVutlVg$hk8T97esnJfp9LNr4FFLdbAsDKMYCEIdNwYwowSSAEs";

export async function loginUser(input: LoginInput) {
  const user = await prisma.user.findUnique({ where: { email: input.email } });
  if (!user || !user.passwordHash) {
    await argon2.verify(DUMMY_PASSWORD_HASH, input.password).catch(() => false);
    throw new UnauthorizedError("Invalid email or password");
  }

  const valid = await argon2.verify(user.passwordHash, input.password);
  if (!valid) {
    throw new UnauthorizedError("Invalid email or password");
  }

  await prisma.user.update({
    where: { id: user.id },
    data: { lastLoginAt: new Date() },
  });

  return createSession(user.id, user.email, true);
}

export async function googleAuth(idToken: string) {
  if (!env.GOOGLE_WEB_CLIENT_ID) {
    throw new AppError(
      501,
      "NOT_CONFIGURED",
      "Google authentication is not configured",
    );
  }

  const client = new OAuth2Client(env.GOOGLE_WEB_CLIENT_ID);
  const ticket = await client.verifyIdToken({
    idToken,
    audience: env.GOOGLE_WEB_CLIENT_ID,
  });
  const payload = ticket.getPayload();
  if (
    !payload ||
    !payload.email ||
    payload.email_verified !== true ||
    !payload.sub
  ) {
    throw new UnauthorizedError("Invalid Google token");
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
    if (user.googleSubject) {
      await prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      });
    } else if (!user.passwordHash) {
      // Google-only account: safe to attach the subject on first sign-in.
      user = await prisma.user.update({
        where: { id: user.id },
        data: { googleSubject, lastLoginAt: new Date() },
      });
    } else {
      // Never silently attach Google to a password account that has no
      // verified email: an attacker could pre-register the victim's address.
      throw new ConflictError(
        "An account with this email already exists. Sign in with your password instead.",
      );
    }
  } else {
    try {
      user = await prisma.user.create({
        data: {
          email,
          googleSubject,
          displayName: payload.name || email.split("@")[0],
          avatarUrl: payload.picture,
        },
      });
    } catch (err) {
      // Two first-time concurrent sign-ins can race on the unique email or
      // googleSubject; recover instead of surfacing a 409 on a login endpoint.
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === "P2002"
      ) {
        user = await prisma.user.findFirst({
          where: { OR: [{ email }, { googleSubject }] },
        });
        if (!user) throw err;
      } else {
        throw err;
      }
    }
  }

  return createSession(user.id, user.email, user.passwordHash !== null);
}

export async function refreshSession(refreshToken: string) {
  const tokenHash = hashToken(refreshToken);
  const now = new Date();

  // Claim the refresh token atomically. This prevents two concurrent refresh
  // requests from both rotating the same token successfully.
  const user = await prisma.$transaction(async (tx) => {
    const session = await tx.authSession.findFirst({
      where: {
        refreshTokenHash: tokenHash,
        revokedAt: null,
        expiresAt: { gt: now },
      },
      select: { id: true, userId: true },
    });

    if (!session)
      throw new UnauthorizedError("Invalid or expired refresh token");

    const claimed = await tx.authSession.updateMany({
      where: { id: session.id, revokedAt: null },
      data: { revokedAt: now },
    });
    if (claimed.count !== 1) {
      throw new UnauthorizedError("Invalid or expired refresh token");
    }

    const sessionUser = await tx.user.findUnique({
      where: { id: session.userId },
      select: { id: true, email: true, passwordHash: true },
    });
    if (!sessionUser) throw new UnauthorizedError('User no longer exists');
    return sessionUser;
  });

  return createSession(user.id, user.email, user.passwordHash !== null);
}

export async function logoutUser(userId: string, refreshToken: string) {
  const tokenHash = hashToken(refreshToken);
  await prisma.authSession.updateMany({
    where: {
      refreshTokenHash: tokenHash,
      userId,
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
      salaryAmount: true,
      paydayFrequency: true,
      paydaySchedule: true,
      createdAt: true,
      lastLoginAt: true,
      passwordHash: true,
    },
  });
  if (!user) throw new NotFoundError("User not found");
  const { passwordHash, ...profile } = user;
  return { ...profile, hasPassword: passwordHash !== null };
}

export async function updateProfile(userId: string, input: UpdateProfileInput) {
  const data: Prisma.UserUpdateInput = {};
  if (input.displayName !== undefined) data.displayName = input.displayName;
  if (input.salaryAmount !== undefined) data.salaryAmount = input.salaryAmount;
  if (input.paydayFrequency !== undefined)
    data.paydayFrequency = input.paydayFrequency;
  if (input.paydaySchedule !== undefined)
    data.paydaySchedule = input.paydaySchedule;
  if (input.minimumBalanceThreshold !== undefined)
    data.minimumBalanceThreshold = input.minimumBalanceThreshold;

  return prisma.user.update({
    where: { id: userId },
    data,
    select: {
      id: true,
      email: true,
      displayName: true,
      avatarUrl: true,
      timezone: true,
      currencyCode: true,
      minimumBalanceThreshold: true,
      salaryAmount: true,
      paydayFrequency: true,
      paydaySchedule: true,
      createdAt: true,
      lastLoginAt: true,
      passwordHash: true,
    },
  }).then(({ passwordHash, ...profile }) => ({
    ...profile,
    hasPassword: passwordHash !== null,
  }));
}

export async function deleteAccount(userId: string, password?: string): Promise<void> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new NotFoundError('User not found');
  }

  // Re-authenticate before an irreversible deletion. Google-only accounts
  // (no password hash) are confirmed by the active session alone.
  if (user.passwordHash) {
    if (!password) {
      throw new ValidationError(
        'Password confirmation is required to delete this account.',
        { password: 'Password confirmation is required' },
      );
    }
    const valid = await argon2.verify(user.passwordHash, password);
    if (!valid) throw new UnauthorizedError('Incorrect password');
  }

  await prisma.$transaction(
    async (tx) => {
      // Delete dependents explicitly in FK-safe order. PostgreSQL enforces
      // RESTRICT on account and category references, so child rows must be
      // removed before their parents. This mirrors prisma/schema.prisma.
      await tx.financialAlert.deleteMany({ where: { userId } });
      await tx.financialSnapshot.deleteMany({ where: { userId } });
      await tx.savingsContribution.deleteMany({ where: { userId } });
      await tx.savingsGoal.deleteMany({ where: { userId } });
      await tx.billInstance.deleteMany({ where: { userId } });
      await tx.billTemplate.deleteMany({ where: { userId } });
      await tx.budget.deleteMany({ where: { userId } });
      await tx.accountTransfer.deleteMany({ where: { userId } });
      await tx.incomeEntry.deleteMany({ where: { userId } });
      await tx.expenseEntry.deleteMany({ where: { userId } });
      await tx.financialAccount.deleteMany({ where: { userId } });
      await tx.expenseCategory.deleteMany({ where: { userId } });
      await tx.authSession.deleteMany({ where: { userId } });
      await tx.user.delete({ where: { id: userId } });
    },
    // Large accounts can hold years of records; the default 5s interactive
    // transaction limit is too tight for the full cascade.
    { timeout: 30000 },
  );
}

export async function exportUserData(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      displayName: true,
      timezone: true,
      currencyCode: true,
      minimumBalanceThreshold: true,
      salaryAmount: true,
      paydayFrequency: true,
      paydaySchedule: true,
      createdAt: true,
      lastLoginAt: true,
      financialAccounts: true,
      incomeEntries: true,
      expenseEntries: true,
      expenseCategories: true,
      budgets: true,
      savingsGoals: {
        include: {
          contributions: true,
        },
      },
      billTemplates: true,
      billInstances: true,
      financialSnapshots: true,
      financialAlerts: true,
    },
  });

  if (!user) {
    throw new NotFoundError('User not found');
  }

  return {
    exportedAt: new Date().toISOString(),
    user,
  };
}

async function createSession(userId: string, email: string, hasPassword: boolean) {
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
    user: { id: userId, email, hasPassword },
  };
}

export async function seedDemoUser() {
  const email = "demo@kasyaba.com";
  const existing = await prisma.user.findUnique({ where: { email } });
  if (!existing) {
    const passwordHash = await argon2.hash("Password123!");
    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        displayName: "Demo User",
        currencyCode: "PHP",
        minimumBalanceThreshold: 5000,
        salaryAmount: 35000,
        paydayFrequency: "semi-monthly",
        paydaySchedule: "15th & 30th",
      },
    });

    await prisma.financialAccount.createMany({
      data: [
        {
          userId: user.id,
          name: "Main Bank Account",
          type: "bank",
          openingBalance: 25000,
        },
        {
          userId: user.id,
          name: "Cash Wallet",
          type: "cash",
          openingBalance: 3000,
        },
        {
          userId: user.id,
          name: "GCash / E-Wallet",
          type: "ewallet",
          openingBalance: 5000,
        },
      ],
    });
  }
}
