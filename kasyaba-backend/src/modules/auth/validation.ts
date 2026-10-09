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

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type GoogleAuthInput = z.infer<typeof googleAuthSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
