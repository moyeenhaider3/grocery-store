import { Request, Response } from 'express';
import { UserService } from '../service/user.service';
import {
  adminListUsersQuerySchema,
  adminCreateUserSchema,
  updateRoleSchema,
  updateBlockedSchema,
} from '../validation/user.schemas';
import { parseOrThrow } from '../validation/auth.schemas';

// Admin access is enforced by the router gate. The actor id always comes from req.user, never the body.
export class AdminUserController {
  public static async list(req: Request, res: Response): Promise<void> {
    const query = parseOrThrow(adminListUsersQuerySchema, req.query);
    const result = await UserService.listForAdmin(query);
    res.status(200).json({ success: true, data: result });
  }

  public static async create(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(adminCreateUserSchema, req.body);
    const user = await UserService.createByAdmin(input);
    res.status(201).json({ success: true, message: 'User created', data: { user } });
  }

  public static async setRole(req: Request, res: Response): Promise<void> {
    const { role } = parseOrThrow(updateRoleSchema, req.body);
    const user = await UserService.setRole(req.user!._id.toString(), String(req.params.id), role);
    res.status(200).json({ success: true, message: 'Role updated', data: { user } });
  }

  public static async setBlocked(req: Request, res: Response): Promise<void> {
    const { isBlocked } = parseOrThrow(updateBlockedSchema, req.body);
    const user = await UserService.setBlocked(req.user!._id.toString(), String(req.params.id), isBlocked);
    res.status(200).json({
      success: true,
      message: isBlocked ? 'User blocked' : 'User unblocked',
      data: { user },
    });
  }
}
