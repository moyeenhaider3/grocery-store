import { Product, IProductDocument, stockStatusOf, StockStatus } from '../models/product.model';
import { Category } from '../models/category.model';
import { AppError } from '../middlewares/error.middleware';
import { assertObjectId, ProductInput, ProductListQuery, ProductUpdateInput } from '../validation/catalog.schemas';

export interface IProductPublic {
  id: string;
  name: string;
  description: string;
  price: number; // integer paise
  stock: number;
  stockStatus: StockStatus;
  category: { id: string; name: string };
  imageUrl: string | null;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type IProductStore = Omit<IProductPublic, 'isActive' | 'updatedAt'>;

export const escapeRegex = (s: string): string => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const SORTS = {
  newest: { createdAt: -1, _id: -1 },
  price_asc: { price: 1, _id: 1 },
  price_desc: { price: -1, _id: -1 },
} as const;

export class ProductService {
  public static toPublic(doc: IProductDocument): IProductPublic {
    const cat = doc.category as unknown as { _id?: { toString(): string }; name?: string } | null;
    const populated = cat && typeof cat === 'object' && 'name' in cat;
    return {
      id: doc._id.toString(),
      name: doc.name,
      description: doc.description,
      price: doc.price,
      stock: doc.stock,
      stockStatus: stockStatusOf(doc.stock),
      category: populated
        ? { id: String(cat!._id), name: cat!.name ?? '' }
        : { id: String(doc.category), name: '' },
      imageUrl: doc.imageUrl ?? null,
      isActive: doc.isActive,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  // Public (storefront) shape: never exposes isActive or updatedAt.
  public static toStore(p: IProductPublic): IProductStore {
    const { isActive: _isActive, updatedAt: _updatedAt, ...rest } = p;
    return rest;
  }

  // Shared query + pagination. Phase 3's public listing must call this with { publicOnly: true }.
  public static async list(filters: ProductListQuery, opts: { publicOnly?: boolean } = {}) {
    const filter: Record<string, unknown> = {};
    if (opts.publicOnly) {
      filter.isActive = true;
    } else if (filters.status === 'active') {
      filter.isActive = true;
    } else if (filters.status === 'inactive') {
      filter.isActive = false;
    }
    if (filters.category) filter.category = assertObjectId(filters.category, 'category');
    if (filters.q) filter.name = { $regex: escapeRegex(filters.q), $options: 'i' };

    const { page, limit } = filters;
    const [total, docs] = await Promise.all([
      Product.countDocuments(filter),
      Product.find(filter)
        .sort(SORTS[filters.sort])
        .skip((page - 1) * limit)
        .limit(limit)
        .populate('category', 'name'),
    ]);
    return {
      items: docs.map((d) => ProductService.toPublic(d)),
      pagination: { total, page, limit, pages: Math.max(1, Math.ceil(total / limit)) },
    };
  }

  public static async create(input: ProductInput): Promise<IProductPublic> {
    if (!(await Category.exists({ _id: input.category }))) {
      throw new AppError('Category does not exist', 400, 'CATEGORY_NOT_FOUND');
    }
    const created = await Product.create(input);
    const doc = await Product.findById(created._id).populate('category', 'name');
    return ProductService.toPublic(doc!);
  }

  public static async getById(id: string): Promise<IProductPublic> {
    assertObjectId(id);
    const doc = await Product.findById(id).populate('category', 'name');
    if (!doc) throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    return ProductService.toPublic(doc);
  }

  // Public getter: inactive and unknown ids give the identical 404.
  public static async getStoreById(id: string): Promise<IProductStore> {
    assertObjectId(id);
    const doc = await Product.findOne({ _id: id, isActive: true }).populate('category', 'name');
    if (!doc) throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    return ProductService.toStore(ProductService.toPublic(doc));
  }

  // Full update. Stock is an absolute value; isActive=false is the soft delete (never removes the document).
  public static async update(id: string, input: ProductUpdateInput): Promise<IProductPublic> {
    assertObjectId(id);
    if (!(await Product.exists({ _id: id }))) {
      throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    }
    if (!(await Category.exists({ _id: input.category }))) {
      throw new AppError('Category does not exist', 400, 'CATEGORY_NOT_FOUND');
    }
    const doc = await Product.findByIdAndUpdate(id, { $set: input }, { returnDocument: 'after', runValidators: true }).populate(
      'category',
      'name',
    );
    if (!doc) throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    return ProductService.toPublic(doc);
  }
}
