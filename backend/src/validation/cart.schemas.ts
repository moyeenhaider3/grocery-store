import mongoose from 'mongoose';
import { z } from 'zod';
import { MAX_LINE_QUANTITY } from '../models/cart.model';

const quantity = z
  .number('Quantity must be a number')
  .int('Quantity must be a whole number')
  .min(1, 'Quantity must be at least 1')
  .max(MAX_LINE_QUANTITY, `Quantity must be at most ${MAX_LINE_QUANTITY}`);

// Only these keys are read; any other client-sent field is ignored.
export const addCartItemSchema = z.object({
  productId: z
    .string('Invalid product id')
    .refine((v) => mongoose.isValidObjectId(v), 'Invalid product id'),
  quantity: quantity.default(1),
});

export const setCartQuantitySchema = z.object({ quantity });

export type AddCartItemInput = z.infer<typeof addCartItemSchema>;
export type SetCartQuantityInput = z.infer<typeof setCartQuantitySchema>;
