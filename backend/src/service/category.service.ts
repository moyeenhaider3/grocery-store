import { Category, ICategoryDocument, categoryKey } from '../models/category.model';
import { Product } from '../models/product.model';
import { AppError } from '../middlewares/error.middleware';
import { assertObjectId } from '../validation/catalog.schemas';

export interface ICategoryPublic {
  id: string;
  name: string;
  productCount: number;
  createdAt: Date;
}

const exists = (): AppError => new AppError('A category with this name already exists', 409, 'CATEGORY_EXISTS');
const notFound = (): AppError => new AppError('Category not found', 404, 'CATEGORY_NOT_FOUND');
const isDuplicateKey = (err: unknown): boolean => (err as { code?: number })?.code === 11000;

export class CategoryService {
  public static toPublic(doc: ICategoryDocument, productCount: number): ICategoryPublic {
    return { id: doc._id.toString(), name: doc.name, productCount, createdAt: doc.createdAt };
  }

  public static async list(): Promise<ICategoryPublic[]> {
    const [categories, counts] = await Promise.all([
      Category.find().sort({ nameKey: 1 }),
      Product.aggregate<{ _id: unknown; count: number }>([{ $group: { _id: '$category', count: { $sum: 1 } } }]),
    ]);
    const countById = new Map(counts.map((c) => [String(c._id), c.count]));
    return categories.map((c) => CategoryService.toPublic(c, countById.get(c._id.toString()) ?? 0));
  }

  // Public storefront list: id + name only, and only categories that hold at least one active product.
  public static async listPublic(): Promise<{ id: string; name: string }[]> {
    const ids = await Product.distinct('category', { isActive: true });
    const categories = await Category.find({ _id: { $in: ids } }).sort({ nameKey: 1 });
    return categories.map((c) => ({ id: c._id.toString(), name: c.name }));
  }

  public static async create(name: string): Promise<ICategoryPublic> {
    const nameKey = categoryKey(name);
    if (await Category.exists({ nameKey })) throw exists();
    try {
      const doc = await Category.create({ name, nameKey });
      return CategoryService.toPublic(doc, 0);
    } catch (err) {
      if (isDuplicateKey(err)) throw exists();
      throw err;
    }
  }

  public static async rename(id: string, name: string): Promise<ICategoryPublic> {
    assertObjectId(id);
    const category = await Category.findById(id);
    if (!category) throw notFound();
    const nameKey = categoryKey(name);
    if (await Category.exists({ nameKey, _id: { $ne: category._id } })) throw exists();
    category.name = name;
    category.nameKey = nameKey;
    try {
      await category.save();
    } catch (err) {
      if (isDuplicateKey(err)) throw exists();
      throw err;
    }
    const count = await Product.countDocuments({ category: category._id });
    return CategoryService.toPublic(category, count);
  }

  public static async remove(id: string): Promise<void> {
    assertObjectId(id);
    const category = await Category.findById(id);
    if (!category) throw notFound();
    // No active-flag filter: inactive products also block deletion.
    const count = await Product.countDocuments({ category: category._id });
    if (count > 0) {
      throw new AppError(
        `Category "${category.name}" still has ${count} product(s) (active or inactive). Move them to another category before deleting it.`,
        409,
        'CATEGORY_IN_USE'
      );
    }
    await category.deleteOne();
  }
}
