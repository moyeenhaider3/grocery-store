import { z } from 'zod';
import { OrderStatus, PaymentMethod } from '../models/order.model';

export const ORDERS_PAGE_SIZE = 20;

const shippingAddressSchema = z.object({
  fullName: z
    .string('Full name is required')
    .trim()
    .min(2, 'Full name must be at least 2 characters')
    .max(80, 'Full name must be at most 80 characters'),
  phone: z
    .string('Phone number is required')
    .transform((v) => v.replace(/[\s-]/g, ''))
    .refine((v) => /^\+?[0-9]{10,13}$/.test(v), 'Enter a valid phone number'),
  addressLine: z
    .string('Address is required')
    .trim()
    .min(5, 'Address must be at least 5 characters')
    .max(200, 'Address must be at most 200 characters'),
  city: z
    .string('City is required')
    .trim()
    .min(2, 'City must be at least 2 characters')
    .max(60, 'City must be at most 60 characters'),
  postalCode: z
    .string('PIN code is required')
    .trim()
    .regex(/^[1-9][0-9]{5}$/, 'Enter a valid 6-digit PIN code'),
});

// Only these keys are read; a client-sent price, total, status, items or userId is stripped.
export const placeOrderSchema = z.object({
  shippingAddress: shippingAddressSchema,
  paymentMethod: z.enum([PaymentMethod.COD, PaymentMethod.MOCK_PAY], 'Choose Cash on Delivery or Pay now'),
});

export const listOrdersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).max(1000).default(1),
});

export const adminListOrdersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).max(1000).default(1),
  // Absent means all statuses.
  status: z.enum(Object.values(OrderStatus) as [OrderStatus, ...OrderStatus[]], 'Choose a valid status').optional(),
});

// PENDING is never a target. Unknown keys (paymentStatus, total, items) are stripped.
export const updateOrderStatusSchema = z.object({
  status: z.enum(
    [OrderStatus.CONFIRMED, OrderStatus.SHIPPED, OrderStatus.DELIVERED, OrderStatus.CANCELLED],
    'Choose a valid status'
  ),
});

export type PlaceOrderInput = z.infer<typeof placeOrderSchema>;
export type ListOrdersQuery = z.infer<typeof listOrdersQuerySchema>;
export type AdminListOrdersQuery = z.infer<typeof adminListOrdersQuerySchema>;
export type UpdateOrderStatusInput = z.infer<typeof updateOrderStatusSchema>;
