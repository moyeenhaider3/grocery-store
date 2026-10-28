import { Request, Response } from 'express';
import { CartService } from '../service/cart.service';
import { addCartItemSchema, setCartQuantitySchema } from '../validation/cart.schemas';
import { parseOrThrow } from '../validation/auth.schemas';

// The user id always comes from the authenticated request, never from client input.
export class CartController {
  public static async get(req: Request, res: Response): Promise<void> {
    const cart = await CartService.getView(req.user!._id.toString());
    res.status(200).json({ success: true, data: { cart } });
  }

  public static async addItem(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(addCartItemSchema, req.body);
    const cart = await CartService.addItem(req.user!._id.toString(), input);
    res.status(200).json({ success: true, data: { cart } });
  }

  public static async updateItem(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(setCartQuantitySchema, req.body);
    const cart = await CartService.setQuantity(req.user!._id.toString(), String(req.params.productId), input);
    res.status(200).json({ success: true, data: { cart } });
  }

  public static async removeItem(req: Request, res: Response): Promise<void> {
    const cart = await CartService.removeItem(req.user!._id.toString(), String(req.params.productId));
    res.status(200).json({ success: true, data: { cart } });
  }
}
