import { Request, Response } from 'express';
import { CategoryService } from '../service/category.service';
import { categoryNameSchema } from '../validation/catalog.schemas';
import { parseOrThrow } from '../validation/auth.schemas';

export class CategoryController {
  public static async list(req: Request, res: Response): Promise<void> {
    const categories = await CategoryService.list();
    res.status(200).json({ success: true, data: { categories } });
  }

  public static async create(req: Request, res: Response): Promise<void> {
    const { name } = parseOrThrow(categoryNameSchema, req.body);
    const category = await CategoryService.create(name);
    res.status(201).json({ success: true, message: 'Category created', data: { category } });
  }

  public static async rename(req: Request, res: Response): Promise<void> {
    const { name } = parseOrThrow(categoryNameSchema, req.body);
    const category = await CategoryService.rename(req.params.id as string, name);
    res.status(200).json({ success: true, message: 'Category renamed', data: { category } });
  }

  public static async remove(req: Request, res: Response): Promise<void> {
    await CategoryService.remove(req.params.id as string);
    res.status(200).json({ success: true, message: 'Category deleted' });
  }
}
