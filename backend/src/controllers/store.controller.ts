import { Request, Response } from 'express';
import { CategoryService } from '../service/category.service';
import { ProductService } from '../service/product.service';
import { storeProductListQuerySchema } from '../validation/catalog.schemas';
import { parseOrThrow } from '../validation/auth.schemas';

export class StoreController {
  public static async listProducts(req: Request, res: Response): Promise<void> {
    const query = parseOrThrow(storeProductListQuerySchema, req.query);
    const { items, pagination } = await ProductService.list({ ...query, status: 'active' }, { publicOnly: true });
    res.status(200).json({ success: true, data: { items: items.map(ProductService.toStore), pagination } });
  }

  public static async getProduct(req: Request, res: Response): Promise<void> {
    const product = await ProductService.getStoreById(String(req.params.id));
    res.status(200).json({ success: true, data: { product } });
  }

  public static async listCategories(req: Request, res: Response): Promise<void> {
    const categories = await CategoryService.listPublic();
    res.status(200).json({ success: true, data: { categories } });
  }
}
