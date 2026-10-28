import { Schema, model, Document, Types } from 'mongoose';

export const MAX_CART_LINES = 50;
export const MAX_LINE_QUANTITY = 100;

export interface ICartItem {
  product: Types.ObjectId;
  quantity: number;
}

export interface ICartDocument extends Document {
  _id: Types.ObjectId;
  user: Types.ObjectId;
  items: ICartItem[];
  createdAt: Date;
  updatedAt: Date;
}

const cartItemSchema = new Schema<ICartItem>(
  {
    product: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
    quantity: {
      type: Number,
      required: true,
      min: [1, 'Quantity must be at least 1'],
      validate: { validator: Number.isInteger, message: 'Quantity must be a whole number' },
    },
  },
  { _id: false }
);

const cartSchema = new Schema<ICartDocument>(
  {
    // One cart per user (CART-05).
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    items: { type: [cartItemSchema], default: [] },
  },
  { timestamps: true, versionKey: false }
);

export const Cart = model<ICartDocument>('Cart', cartSchema);
