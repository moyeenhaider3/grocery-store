import { Schema, model, Document, Types } from 'mongoose';

export interface ICategory {
  _id: Types.ObjectId;
  name: string;
  nameKey: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ICategoryDocument extends ICategory, Document {
  _id: Types.ObjectId;
}

// Case-insensitive identity of a category name (also used to match CSV import rows).
export const categoryKey = (name: string): string => name.trim().toLowerCase();

const categorySchema = new Schema<ICategoryDocument>(
  {
    name: {
      type: String,
      required: [true, 'Category name is required'],
      trim: true,
      maxlength: [50, 'Category name cannot exceed 50 characters'],
    },
    nameKey: {
      type: String,
      required: true,
      unique: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

export const Category = model<ICategoryDocument>('Category', categorySchema);
