import mongoose from 'mongoose';
import { z } from 'zod';
import { AppError } from '../middlewares/error.middleware';

export const categoryNameSchema = z.object({
  name: z.string().trim().min(1, 'Category name is required').max(50, 'Category name must be at most 50 characters'),
});

// Reject malformed ids up front so they never become a Mongoose CastError (500).
export const assertObjectId = (id: unknown, label = 'id'): string => {
  if (typeof id !== 'string' || !mongoose.isValidObjectId(id)) {
    throw new AppError(`Invalid ${label}`, 400, 'INVALID_ID');
  }
  return id;
};

const isHttpUrl = (v: string): boolean => {
  try {
    const u = new URL(v);
    return u.protocol === 'http:' || u.protocol === 'https:';
  } catch {
    return false;
  }
};

// The ONE product rule set: used by create, update and every CSV row.
export const productInputSchema = z.object({
  name: z.string().trim().min(1, 'Name is required').max(120, 'Name must be at most 120 characters'),
  description: z.string().trim().max(2000, 'Description must be at most 2000 characters').default(''),
  price: z
    .number()
    .int('Price must be a whole number of paise')
    .min(1, 'Price must be greater than 0')
    .max(1_000_000_000, 'Price is too large'),
  stock: z
    .number()
    .int('Stock must be a whole number')
    .min(0, 'Stock cannot be negative')
    .max(1_000_000, 'Stock is too large'),
  category: z.string().refine((v) => mongoose.isValidObjectId(v), 'Category is required'),
  imageUrl: z
    .string()
    .trim()
    .nullish()
    .transform((v) => (v ? v : null))
    .refine((v) => v === null || (v.length <= 2048 && isHttpUrl(v)), 'Image URL must start with http:// or https://'),
  isActive: z.boolean().default(true),
});
export type ProductInput = z.infer<typeof productInputSchema>;

// Edits always state isActive explicitly so an omitted flag can never reactivate a product.
export const productUpdateSchema = productInputSchema.extend({
  isActive: z.boolean({ error: 'isActive is required' }),
});
export type ProductUpdateInput = z.infer<typeof productUpdateSchema>;

export const productListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).max(10_000).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  q: z.string().trim().max(100).optional(),
  status: z.enum(['all', 'active', 'inactive']).default('all'),
  category: z.string().optional(),
  sort: z.enum(['newest', 'price_asc', 'price_desc']).default('newest'),
});
export type ProductListQuery = z.infer<typeof productListQuerySchema>;

// Public listing: no status key, so a client-sent status is stripped and can never widen the scope.
export const storeProductListQuerySchema = productListQuerySchema.omit({ status: true });
export type StoreProductListQuery = z.infer<typeof storeProductListQuerySchema>;
