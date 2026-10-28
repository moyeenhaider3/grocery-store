import { Schema, model, Document, Types } from 'mongoose';

// Single server-side source of truth for "low stock" (the app never copies it).
export const LOW_STOCK_THRESHOLD = 5;

export type StockStatus = 'in_stock' | 'low_stock' | 'out_of_stock';

export const stockStatusOf = (stock: number): StockStatus => {
  if (stock <= 0) return 'out_of_stock';
  if (stock <= LOW_STOCK_THRESHOLD) return 'low_stock';
  return 'in_stock';
};

export interface IProduct {
  _id: Types.ObjectId;
  name: string;
  description: string;
  price: number; // integer paise
  stock: number;
  category: Types.ObjectId;
  imageUrl: string | null;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface IProductDocument extends IProduct, Document {
  _id: Types.ObjectId;
}

const productSchema = new Schema<IProductDocument>(
  {
    name: {
      type: String,
      required: [true, 'Product name is required'],
      trim: true,
      maxlength: [120, 'Product name cannot exceed 120 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [2000, 'Description cannot exceed 2000 characters'],
      default: '',
    },
    price: {
      type: Number,
      required: [true, 'Price is required'],
      min: [1, 'Price must be greater than 0'],
      validate: { validator: Number.isInteger, message: 'Price must be a whole number of paise' },
    },
    stock: {
      type: Number,
      required: [true, 'Stock is required'],
      min: [0, 'Stock cannot be negative'],
      validate: { validator: Number.isInteger, message: 'Stock must be a whole number' },
    },
    category: {
      type: Schema.Types.ObjectId,
      ref: 'Category',
      required: [true, 'Category is required'],
    },
    imageUrl: {
      type: String,
      trim: true,
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

productSchema.index({ category: 1 });
productSchema.index({ isActive: 1, createdAt: -1 });
productSchema.index({ createdAt: -1 });
productSchema.index({ isActive: 1, price: 1 });

export const Product = model<IProductDocument>('Product', productSchema);
