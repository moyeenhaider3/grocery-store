import { Request, Response } from 'express';
import { OrderService } from '../service/order.service';
import { adminListOrdersQuerySchema, updateOrderStatusSchema } from '../validation/order.schemas';
import { parseOrThrow } from '../validation/auth.schemas';

// Admin access is enforced by the router gate (authenticate + restrictTo ADMIN).
export class AdminOrderController {
  public static async list(req: Request, res: Response): Promise<void> {
    const query = parseOrThrow(adminListOrdersQuerySchema, req.query);
    const result = await OrderService.listAll(query);
    res.status(200).json({ success: true, data: result });
  }

  public static async get(req: Request, res: Response): Promise<void> {
    const order = await OrderService.getAny(String(req.params.id));
    res.status(200).json({ success: true, data: { order } });
  }

  public static async updateStatus(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(updateOrderStatusSchema, req.body);
    const order = await OrderService.updateStatus(String(req.params.id), input);
    res.status(200).json({ success: true, message: 'Order status updated', data: { order } });
  }
}
