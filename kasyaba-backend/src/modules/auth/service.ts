import crypto from "crypto";
import * as argon2 from "argon2";
import { OAuth2Client } from "google-auth-library";
import { prisma } from "../../config/database";
import { signAccessToken, signResetToken, verifyResetToken } from "../../middleware/auth";
import { sendOtpEmail } from "../../lib/email";
import {
  AppError,
  ConflictError,
  NotFoundError,
  UnauthorizedError,
  ValidationError,
} from "../../lib/errors";
import { env } from "../../config/env";
import { Prisma } from "@prisma/client";
import { logger } from "../../lib/logger";
import { generateBillInstances } from "../bills/service";
import type {
  RegisterInput,
  LoginInput,
  UpdateProfileInput,
  RestoreInput,
  ChangePasswordInput,
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

/**
 * Restore payloads are user-supplied JSON. Coerce optional dates safely so a
 * malformed value cannot abort an otherwise valid restore with an Invalid Date.
 */
function parseDate(value: unknown): Date | null {
  if (value === undefined || value === null || value === "") return null;
  const date = value instanceof Date ? value : new Date(value as string | number);
  return Number.isNaN(date.getTime()) ? null : date;
}

function parseDateOr(value: unknown, fallback: Date): Date {
  return parseDate(value) ?? fallback;
}

function parseIntegerInRange(
  value: unknown,
  min: number,
  max: number,
): number | null {
  if (value === undefined || value === null || value === "") return null;
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isInteger(parsed) && parsed >= min && parsed <= max
    ? parsed
    : null;
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
      transfers: true,
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

export async function restoreUserData(userId: string, input: RestoreInput) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new NotFoundError('User not found');
  }

  const source =
    input.user && typeof input.user === 'object'
      ? (input.user as Record<string, any>)
      : (input as Record<string, any>);

  const accounts: any[] = Array.isArray(source.financialAccounts)
    ? source.financialAccounts
    : Array.isArray(source.accounts)
      ? source.accounts
      : [];
  const categories: any[] = Array.isArray(source.expenseCategories)
    ? source.expenseCategories
    : Array.isArray(source.categories)
      ? source.categories
      : [];
  const expenses: any[] = Array.isArray(source.expenseEntries)
    ? source.expenseEntries
    : Array.isArray(source.expenses)
      ? source.expenses
      : [];
  const incomes: any[] = Array.isArray(source.incomeEntries)
    ? source.incomeEntries
    : Array.isArray(source.income)
      ? source.income
      : [];
  const transfers: any[] = Array.isArray(source.transfers)
    ? source.transfers
    : Array.isArray(source.accountTransfers)
      ? source.accountTransfers
      : [];
  const goals: any[] = Array.isArray(source.savingsGoals)
    ? source.savingsGoals
    : Array.isArray(source.goals)
      ? source.goals
      : [];
  const budgets: any[] = Array.isArray(source.budgets) ? source.budgets : [];
  const bills: any[] = Array.isArray(source.billTemplates)
    ? source.billTemplates
    : Array.isArray(source.bills)
      ? source.bills
      : [];

  // Contributions are exported nested under each goal, but accept a flat
  // collection too so hand-built/older backups keep working.
  const contributions: Array<{ entry: any; parentGoalId?: string }> = [];
  for (const goal of goals) {
    if (!Array.isArray(goal.contributions)) continue;
    for (const entry of goal.contributions) {
      contributions.push({ entry, parentGoalId: goal.id });
    }
  }
  const flatContributions: any[] = Array.isArray(source.savingsContributions)
    ? source.savingsContributions
    : Array.isArray(source.contributions)
      ? source.contributions
      : [];
  for (const entry of flatContributions) {
    contributions.push({ entry });
  }

  const result = await prisma.$transaction(
    async (tx) => {
      // 1. Update user settings if present
      const profileUpdates: Prisma.UserUpdateInput = {};
      if (source.salaryAmount !== undefined && source.salaryAmount !== null) {
        profileUpdates.salaryAmount = source.salaryAmount;
      }
      if (source.paydayFrequency !== undefined && source.paydayFrequency !== null) {
        profileUpdates.paydayFrequency = source.paydayFrequency;
      }
      if (source.paydaySchedule !== undefined && source.paydaySchedule !== null) {
        profileUpdates.paydaySchedule = source.paydaySchedule;
      }
      if (source.minimumBalanceThreshold !== undefined && source.minimumBalanceThreshold !== null) {
        profileUpdates.minimumBalanceThreshold = source.minimumBalanceThreshold;
      }
      if (Object.keys(profileUpdates).length > 0) {
        await tx.user.update({
          where: { id: userId },
          data: profileUpdates,
        });
      }

      // 2. Categories
      let restoredCategories = 0;
      for (const cat of categories) {
        if (!cat.id || !cat.name) continue;
        await tx.expenseCategory.upsert({
          where: { id: cat.id },
          update: {
            name: cat.name,
            iconKey: cat.iconKey ?? cat.icon ?? 'receipt',
          },
          create: {
            id: cat.id,
            userId,
            name: cat.name,
            iconKey: cat.iconKey ?? cat.icon ?? 'receipt',
          },
        });
        restoredCategories++;
      }

      // 3. Accounts
      let restoredAccounts = 0;
      for (const acc of accounts) {
        if (!acc.id || !acc.name) continue;
        await tx.financialAccount.upsert({
          where: { id: acc.id },
          update: {
            name: acc.name,
            type: acc.type ?? 'cash',
            currencyCode: acc.currencyCode ?? acc.currency ?? 'PHP',
            openingBalance: acc.openingBalance ?? 0,
            isArchived: acc.isArchived ?? false,
          },
          create: {
            id: acc.id,
            userId,
            name: acc.name,
            type: acc.type ?? 'cash',
            currencyCode: acc.currencyCode ?? acc.currency ?? 'PHP',
            openingBalance: acc.openingBalance ?? 0,
            isArchived: acc.isArchived ?? false,
            createdAt: acc.createdAt ? new Date(acc.createdAt) : new Date(),
          },
        });
        restoredAccounts++;
      }

      // 4. Expenses
      let restoredExpenses = 0;
      for (const exp of expenses) {
        if (!exp.id || exp.amount === undefined || !exp.accountId || !exp.categoryId) continue;
        await tx.expenseEntry.upsert({
          where: { id: exp.id },
          update: {
            accountId: exp.accountId,
            categoryId: exp.categoryId,
            amount: exp.amount,
            description: exp.description ?? 'Expense',
            spentAt: exp.spentAt ? new Date(exp.spentAt) : new Date(),
            status: exp.status ?? 'posted',
            notes: exp.notes,
          },
          create: {
            id: exp.id,
            userId,
            accountId: exp.accountId,
            categoryId: exp.categoryId,
            amount: exp.amount,
            description: exp.description ?? 'Expense',
            spentAt: exp.spentAt ? new Date(exp.spentAt) : new Date(),
            status: exp.status ?? 'posted',
            notes: exp.notes,
            createdAt: exp.createdAt ? new Date(exp.createdAt) : new Date(),
          },
        });
        restoredExpenses++;
      }

      // 5. Incomes
      let restoredIncomes = 0;
      for (const inc of incomes) {
        if (!inc.id || inc.amount === undefined || !inc.accountId) continue;
        await tx.incomeEntry.upsert({
          where: { id: inc.id },
          update: {
            accountId: inc.accountId,
            amount: inc.amount,
            source: inc.source ?? 'Income',
            receivedAt: inc.receivedAt ? new Date(inc.receivedAt) : new Date(),
            status: inc.status ?? 'posted',
            notes: inc.notes,
          },
          create: {
            id: inc.id,
            userId,
            accountId: inc.accountId,
            amount: inc.amount,
            source: inc.source ?? 'Income',
            receivedAt: inc.receivedAt ? new Date(inc.receivedAt) : new Date(),
            status: inc.status ?? 'posted',
            notes: inc.notes,
            createdAt: inc.createdAt ? new Date(inc.createdAt) : new Date(),
          },
        });
        restoredIncomes++;
      }

      // 6. Transfers
      let restoredTransfers = 0;
      for (const tr of transfers) {
        if (!tr.id || tr.amount === undefined || !tr.fromAccountId || !tr.toAccountId) continue;
        await tx.accountTransfer.upsert({
          where: { id: tr.id },
          update: {
            fromAccountId: tr.fromAccountId,
            toAccountId: tr.toAccountId,
            amount: tr.amount,
            transferredAt: tr.transferredAt ? new Date(tr.transferredAt) : new Date(),
            notes: tr.notes,
          },
          create: {
            id: tr.id,
            userId,
            fromAccountId: tr.fromAccountId,
            toAccountId: tr.toAccountId,
            amount: tr.amount,
            transferredAt: tr.transferredAt ? new Date(tr.transferredAt) : new Date(),
            notes: tr.notes,
            createdAt: tr.createdAt ? new Date(tr.createdAt) : new Date(),
          },
        });
        restoredTransfers++;
      }

      // 7. Goals
      let restoredGoals = 0;
      const restoredGoalIds = new Set<string>();
      for (const g of goals) {
        if (!g.id || !g.name || g.targetAmount === undefined) continue;
        await tx.savingsGoal.upsert({
          where: { id: g.id },
          update: {
            name: g.name,
            targetAmount: g.targetAmount,
            targetDate: g.targetDate ? new Date(g.targetDate) : null,
            status: g.status ?? 'active',
          },
          create: {
            id: g.id,
            userId,
            name: g.name,
            targetAmount: g.targetAmount,
            targetDate: g.targetDate ? new Date(g.targetDate) : null,
            status: g.status ?? 'active',
            createdAt: g.createdAt ? new Date(g.createdAt) : new Date(),
          },
        });
        restoredGoalIds.add(g.id);
        restoredGoals++;
      }

      // 8. Goal contributions. Only attach to goals restored in this pass so a
      // malformed backup cannot write contributions under another user's goal.
      let restoredContributions = 0;
      const seenContributionIds = new Set<string>();
      for (const { entry: c, parentGoalId } of contributions) {
        if (!c || typeof c !== 'object') continue;
        const contributionId = c.id;
        const goalId = c.goalId ?? parentGoalId;
        if (
          !contributionId ||
          !goalId ||
          c.amount === undefined ||
          seenContributionIds.has(contributionId) ||
          !restoredGoalIds.has(goalId)
        ) {
          continue;
        }
        seenContributionIds.add(contributionId);
        const contributedAt =
          parseDate(c.contributedAt) ?? parseDate(c.createdAt) ?? new Date();
        await tx.savingsContribution.upsert({
          where: { id: contributionId },
          update: {
            userId,
            goalId,
            amount: c.amount,
            contributedAt,
            notes: c.notes ?? null,
          },
          create: {
            id: contributionId,
            userId,
            goalId,
            amount: c.amount,
            contributedAt,
            notes: c.notes ?? null,
            createdAt: parseDate(c.createdAt) ?? contributedAt,
          },
        });
        restoredContributions++;
      }

      // 9. Budgets (a null categoryId is a valid global budget)
      let restoredBudgets = 0;
      for (const b of budgets) {
        if (!b.id || b.amount === undefined) continue;
        const categoryId = b.categoryId ?? null;
        const startsOn = parseDateOr(b.startsOn ?? b.month, new Date());
        await tx.budget.upsert({
          where: { id: b.id },
          update: {
            categoryId,
            amount: b.amount,
            startsOn,
          },
          create: {
            id: b.id,
            userId,
            categoryId,
            amount: b.amount,
            startsOn,
            createdAt: b.createdAt ? new Date(b.createdAt) : new Date(),
          },
        });
        restoredBudgets++;
      }

      // 10. Bill templates
      let restoredBills = 0;
      for (const bill of bills) {
        if (!bill.id || !bill.name || (bill.defaultAmount === undefined && bill.amount === undefined)) continue;
        const defaultAmount = bill.defaultAmount ?? bill.amount;
        const startsOn = parseDateOr(bill.startsOn, new Date());
        const recurrence = (bill.recurrence === 'weekly' || bill.recurrence === 'monthly' || bill.recurrence === 'none')
          ? bill.recurrence
          : 'monthly';

        // Pre-fix exports dropped the anchor to day 1. Recover the true anchor
        // from startsOn instead, in UTC to match bill generation.
        let dayOfMonth = parseIntegerInRange(bill.dayOfMonth, 1, 31);
        let dayOfWeek = parseIntegerInRange(bill.dayOfWeek, 0, 6);
        if (recurrence === 'monthly') {
          dayOfMonth =
            dayOfMonth ??
            parseIntegerInRange(bill.dueDay, 1, 31) ??
            startsOn.getUTCDate();
        } else if (recurrence === 'weekly') {
          dayOfWeek = dayOfWeek ?? startsOn.getUTCDay();
        }

        const endsOn = parseDate(bill.endsOn);
        const reminderLeadDays =
          parseIntegerInRange(bill.reminderLeadDays, 0, 30) ?? 1;

        await tx.billTemplate.upsert({
          where: { id: bill.id },
          update: {
            name: bill.name,
            defaultAmount,
            categoryId: bill.categoryId ?? null,
            recurrence,
            dayOfWeek,
            dayOfMonth,
            startsOn,
            endsOn,
            reminderLeadDays,
            isActive: bill.isActive ?? true,
          },
          create: {
            id: bill.id,
            userId,
            name: bill.name,
            defaultAmount,
            categoryId: bill.categoryId ?? null,
            recurrence,
            dayOfWeek,
            dayOfMonth,
            startsOn,
            endsOn,
            reminderLeadDays,
            isActive: bill.isActive ?? true,
            createdAt: bill.createdAt ? new Date(bill.createdAt) : new Date(),
          },
        });
        restoredBills++;
      }

      return {
        restoredAt: new Date().toISOString(),
        counts: {
          accounts: restoredAccounts,
          expenses: restoredExpenses,
          incomes: restoredIncomes,
          transfers: restoredTransfers,
          categories: restoredCategories,
          goals: restoredGoals,
          contributions: restoredContributions,
          budgets: restoredBudgets,
          bills: restoredBills,
        },
      };
    },
    { timeout: 30000 },
  );

  // The worker only generates bill instances hourly. Kick off a pass now so a
  // freshly restored account does not show an empty Bills tab. Failure here is
  // non-fatal: the data is already committed and the worker will retry.
  try {
    await generateBillInstances(userId);
  } catch (err) {
    logger.error(
      { err, userId },
      'Failed to generate bill instances after restore',
    );
  }

  return result;
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

export async function requestPasswordReset(email: string): Promise<void> {
  const normalizedEmail = email.trim().toLowerCase();
  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  });
  if (!user) {
    // Return early to prevent user email enumeration
    return;
  }

  // Invalidate any existing unused OTPs for this user
  await prisma.passwordResetOtp.deleteMany({
    where: { userId: user.id },
  });

  // Generate a secure 6-digit numeric OTP (100000 - 999999)
  const otp = crypto.randomInt(100000, 1000000).toString();
  const otpHash = hashToken(otp);
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  await prisma.passwordResetOtp.create({
    data: {
      userId: user.id,
      otpHash,
      expiresAt,
    },
  });

  // Send email via Resend (skips gracefully if RESEND_API_KEY is not configured)
  await sendOtpEmail(user.email, otp);
}

export async function verifyOtp(
  email: string,
  otp: string,
): Promise<{ resetToken: string }> {
  const normalizedEmail = email.trim().toLowerCase();
  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  });
  if (!user) {
    throw new ValidationError("Invalid or expired verification code");
  }

  const normalizedOtp = otp.trim();
  const incomingHash = hashToken(normalizedOtp);

  const otpRecord = await prisma.passwordResetOtp.findFirst({
    where: {
      userId: user.id,
      usedAt: null,
    },
    orderBy: { createdAt: "desc" },
  });

  if (!otpRecord) {
    throw new ValidationError("No active verification code found");
  }

  if (otpRecord.expiresAt < new Date()) {
    throw new ValidationError("Verification code has expired");
  }

  if (otpRecord.otpHash !== incomingHash) {
    throw new ValidationError("Invalid or expired verification code");
  }

  // Mark OTP as used
  await prisma.passwordResetOtp.update({
    where: { id: otpRecord.id },
    data: { usedAt: new Date() },
  });

  const resetToken = await signResetToken({
    sub: user.id,
    email: user.email,
  });

  return { resetToken };
}

export async function resetPassword(
  param1: string,
  param2?: string,
  param3?: string,
): Promise<void> {
  let userId: string;
  let newPassword: string;

  if (param3 !== undefined) {
    // Called with (email, token, newPassword)
    const email = param1.trim().toLowerCase();
    const token = param2;
    newPassword = param3;

    if (token && token.split(".").length === 3) {
      const payload = await verifyResetToken(token);
      userId = payload.sub;
    } else {
      const user = await prisma.user.findUnique({
        where: { email },
      });
      if (!user) {
        throw new NotFoundError("User not found");
      }
      userId = user.id;
    }
  } else {
    // Called with (resetToken, newPassword)
    const resetToken = param1;
    newPassword = param2!;
    const payload = await verifyResetToken(resetToken);
    userId = payload.sub;
  }

  const passwordHash = await argon2.hash(newPassword);
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash },
  });

  // Revoke previous sessions on password reset
  await prisma.authSession.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

export async function changePassword(
  userId: string,
  input: ChangePasswordInput,
): Promise<void> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new NotFoundError("User not found");
  }

  if (input.currentPassword === input.newPassword) {
    throw new ValidationError(
      "New password must be different from your current password",
    );
  }

  if (user.passwordHash) {
    const valid = await argon2.verify(user.passwordHash, input.currentPassword);
    if (!valid) {
      throw new ValidationError("Current password is incorrect", {
        currentPassword: "Current password is incorrect",
      });
    }

    const isSame = await argon2.verify(user.passwordHash, input.newPassword);
    if (isSame) {
      throw new ValidationError(
        "New password must be different from your current password",
      );
    }
  }

  const newHash = await argon2.hash(input.newPassword);
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash: newHash },
  });
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
