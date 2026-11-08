import { z } from 'zod';

export const registerSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .max(254, 'Email address is too long')
    .transform((e) => e.toLowerCase()),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(128, 'Password must be at most 128 characters'),
  displayName: z.string().min(1, 'Display name is required').max(100).optional(),
});

export const loginSchema = z.object({
  email: z.string().email().max(254).transform((e) => e.toLowerCase()),
  password: z.string().min(1, 'Password is required').max(128),
});

export const googleAuthSchema = z.object({
  idToken: z.string().min(1, 'Google ID token is required').max(4096),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required').max(512),
});

export const deleteAccountSchema = z.object({
  // Required when the account has a password; omitted for Google-only
  // accounts, where the active session is the confirmation.
  password: z.string().min(1).max(128).optional(),
});

export const forgotPasswordSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .max(254)
    .transform((e) => e.toLowerCase()),
});

export const verifyOtpSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .max(254)
    .transform((e) => e.toLowerCase()),
  otp: z
    .string()
    .trim()
    .regex(/^\d{6}$/, 'Verification code must be exactly 6 digits'),
});

export const resetPasswordSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .max(254)
    .transform((e) => e.toLowerCase())
    .optional(),
  token: z.string().min(1, 'Reset token is required').optional(),
  newPassword: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(128, 'Password must be at most 128 characters'),
});

export const changePasswordSchema = z
  .object({
    currentPassword: z.string().min(1, 'Current password is required').max(128),
    newPassword: z
      .string()
      .min(8, 'New password must be at least 8 characters')
      .max(128, 'New password must be at most 128 characters'),
  })
  .refine((data) => data.currentPassword !== data.newPassword, {
    message: 'New password must be different from your current password',
    path: ['newPassword'],
  });

const moneySchema = z
  .string()
  .regex(/^(?:0|[1-9]\d{0,11})(?:\.\d{1,2})?$/, 'Invalid amount format');

export const updateProfileSchema = z.object({
  displayName: z.string().trim().min(1).max(100).nullable().optional(),
  salaryAmount: moneySchema.nullable().optional(),
  paydayFrequency: z.string().trim().min(1).max(50).nullable().optional(),
  paydaySchedule: z.string().trim().min(1).max(100).nullable().optional(),
  minimumBalanceThreshold: moneySchema.optional(),
});

export const restoreSchema = z
  .object({
    exportedAt: z.string().optional(),
    user: z.record(z.any()).optional(),
    financialAccounts: z.array(z.record(z.any())).optional(),
    expenseEntries: z.array(z.record(z.any())).optional(),
    incomeEntries: z.array(z.record(z.any())).optional(),
    transfers: z.array(z.record(z.any())).optional(),
    budgets: z.array(z.record(z.any())).optional(),
    savingsGoals: z.array(z.record(z.any())).optional(),
    billTemplates: z.array(z.record(z.any())).optional(),
    expenseCategories: z.array(z.record(z.any())).optional(),
  })
  .passthrough();

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type GoogleAuthInput = z.infer<typeof googleAuthSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type RestoreInput = z.infer<typeof restoreSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
