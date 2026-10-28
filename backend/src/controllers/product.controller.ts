import { Request, Response } from 'express';
import { ProductService } from '../service/product.service';
import { productInputSchema, productListQuerySchema, productUpdateSchema } from '../validation/catalog.schemas';
import { parseOrThrow } from '../validation/auth.schemas';

export class ProductController {
  public static async list(req: Request, res: Response): Promise<void> {
    const query = parseOrThrow(productListQuerySchema, req.query);
    const { items, pagination } = await ProductService.list(query);
    res.status(200).json({ success: true, data: { items, pagination } });
  }

  public static async create(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(productInputSchema, req.body);
    const product = await ProductService.create(input);
    res.status(201).json({ success: true, message: 'Product created', data: { product } });
  }

  public static async get(req: Request, res: Response): Promise<void> {
    const product = await ProductService.getById(String(req.params.id));
    res.status(200).json({ success: true, data: { product } });
  }

  public static async update(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(productUpdateSchema, req.body);
    const product = await ProductService.update(String(req.params.id), input);
    res.status(200).json({ success: true, message: 'Product updated', data: { product } });
  }
}
