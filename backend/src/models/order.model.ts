import { Schema, model, Document, Types } from 'mongoose';

export enum OrderStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  SHIPPED = 'SHIPPED',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED',
}

export enum PaymentMethod {
  COD = 'COD',
  MOCK_PAY = 'MOCK_PAY',
}

export enum PaymentStatus {
  UNPAID = 'UNPAID',
  PAID = 'PAID',
  REFUNDED = 'REFUNDED',
}

export interface IOrderItem {
  product: Types.ObjectId;
  name: string;
  imageUrl: string | null;
  unitPrice: number; // integer paise, snapshot at placement
  quantity: number;
  lineTotal: number;
}

export interface IShippingAddress {
  fullName: string;
  phone: string;
  addressLine: string;
  city: string;
  postalCode: string;
}

export interface IStatusEntry {
  status: OrderStatus;
  at: Date;
}

export interface IOrderDocument extends Document {
  _id: Types.ObjectId;
  user: Types.ObjectId;
  items: IOrderItem[];
  shippingAddress: IShippingAddress;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  status: OrderStatus;
  statusHistory: IStatusEntry[];
  total: number;
  // Set once when a cancelled order's stock has been returned; makes restock run at most once.
  restocked?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const positiveInt = {
  type: Number,
  required: true,
  min: 1,
  validate: { validator: Number.isInteger, message: 'Must be a whole number' },
};

const orderItemSchema = new Schema<IOrderItem>(
  {
    product: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
    name: { type: String, required: true },
    imageUrl: { type: String, default: null },
    unitPrice: positiveInt,
    quantity: positiveInt,
    lineTotal: positiveInt,
  },
  { _id: false }
);

const shippingAddressSchema = new Schema<IShippingAddress>(
  {
    fullName: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    addressLine: { type: String, required: true, trim: true },
    city: { type: String, required: true, trim: true },
    postalCode: { type: String, required: true, trim: true },
  },
  { _id: false }
);

const statusEntrySchema = new Schema<IStatusEntry>(
  {
    status: { type: String, enum: Object.values(OrderStatus), required: true },
    at: { type: Date, required: true, default: Date.now },
  },
  { _id: false }
);

const orderSchema = new Schema<IOrderDocument>(
  {
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    items: {
      type: [orderItemSchema],
      validate: { validator: (v: unknown[]) => v.length >= 1, message: 'Order must have at least one item' },
    },
    shippingAddress: { type: shippingAddressSchema, required: true },
    paymentMethod: { type: String, enum: Object.values(PaymentMethod), required: true },
    paymentStatus: { type: String, enum: Object.values(PaymentStatus), default: PaymentStatus.UNPAID },
    status: { type: String, enum: Object.values(OrderStatus), default: OrderStatus.PENDING },
    statusHistory: { type: [statusEntrySchema], default: [] },
    total: positiveInt,
    restocked: { type: Boolean, default: false },
  },
  { timestamps: true, versionKey: false }
);

// My-orders list, and the Phase 6 admin status filter.
orderSchema.index({ user: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });

export const Order = model<IOrderDocument>('Order', orderSchema);
