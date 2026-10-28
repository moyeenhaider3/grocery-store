import { z } from 'zod';
import { AppError } from '../middlewares/error.middleware';

const emailSchema = z.string().trim().toLowerCase().pipe(z.email().max(254));

export const nameSchema = z.string().trim().min(2, 'Name must be at least 2 characters').max(50, 'Name must be at most 50 characters');

export const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .max(128, 'Password must be at most 128 characters')
  .refine((p) => Buffer.byteLength(p, 'utf8') <= 72, 'Password must be at most 72 bytes');

// z.object strips unknown keys, so a client-sent `role` never survives parsing.
export const signupSchema = z.object({
  name: nameSchema,
  email: emailSchema,
  password: passwordSchema,
});

export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Password is required').max(128),
});

export type SignupInput = z.infer<typeof signupSchema>;
export type LoginInput = z.infer<typeof loginSchema>;

// Express 5 leaves req.body undefined when no body is sent, hence `?? {}`.
export const parseOrThrow = <T extends z.ZodType>(schema: T, body: unknown): z.infer<T> => {
  const result = schema.safeParse(body ?? {});
  if (!result.success) {
    throw new AppError(result.error.issues[0]?.message ?? 'Invalid input', 400, 'VALIDATION_ERROR');
  }
  return result.data;
};
