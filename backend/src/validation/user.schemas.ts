import { z } from 'zod';
import { nameSchema, passwordSchema, signupSchema } from './auth.schemas';
import { UserRole } from '../models/user.model';

// z.object strips unknown keys, so role/email/isBlocked/passwordHash never survive parsing.
export const updateProfileSchema = z.object({
  name: nameSchema,
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required').max(128),
  newPassword: passwordSchema,
});

export const USERS_PAGE_SIZE = 20;

const roleSchema = z.enum([UserRole.USER, UserRole.ADMIN], 'Role must be USER or ADMIN');

export const adminListUsersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).max(1000).default(1),
  q: z.string().trim().max(100).optional(),
});

// Role is explicit; isBlocked, passwordHash and any other key is stripped.
export const adminCreateUserSchema = signupSchema.extend({ role: roleSchema });

export const updateRoleSchema = z.object({ role: roleSchema });

export const updateBlockedSchema = z.object({
  isBlocked: z.boolean('isBlocked must be true or false'),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
export type AdminListUsersQuery = z.infer<typeof adminListUsersQuerySchema>;
export type AdminCreateUserInput = z.infer<typeof adminCreateUserSchema>;
export type UpdateRoleInput = z.infer<typeof updateRoleSchema>;
export type UpdateBlockedInput = z.infer<typeof updateBlockedSchema>;
