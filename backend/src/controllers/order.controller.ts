import { Request, Response } from 'express';
import { OrderService } from '../service/order.service';
import { placeOrderSchema, listOrdersQuerySchema } from '../validation/order.schemas';
import { parseOrThrow } from '../validation/auth.schemas';

// The user id always comes from the authenticated request, never from client input.
export class OrderController {
  public static async place(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(placeOrderSchema, req.body);
    const order = await OrderService.placeOrder(req.user!._id.toString(), input);
    res.status(201).json({ success: true, message: 'Order placed', data: { order } });
  }

  public static async listMine(req: Request, res: Response): Promise<void> {
    const query = parseOrThrow(listOrdersQuerySchema, req.query);
    const result = await OrderService.listMine(req.user!._id.toString(), query);
    res.status(200).json({ success: true, data: result });
  }

  public static async getMine(req: Request, res: Response): Promise<void> {
    const order = await OrderService.getMine(req.user!._id.toString(), String(req.params.id));
    res.status(200).json({ success: true, data: { order } });
  }

  public static async cancelMine(req: Request, res: Response): Promise<void> {
    const order = await OrderService.cancelMine(req.user!._id.toString(), String(req.params.id));
    res.status(200).json({ success: true, message: 'Order cancelled', data: { order } });
  }
}
