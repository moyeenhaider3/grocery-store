import { Request, Response } from 'express';
import { UserService } from '../service/user.service';
import { changePasswordSchema, updateProfileSchema } from '../validation/user.schemas';
import { parseOrThrow } from '../validation/auth.schemas';

// The user id always comes from the authenticated request, never from client input.
export class UserController {
  public static async getMe(req: Request, res: Response): Promise<void> {
    res.status(200).json({ success: true, data: { user: UserService.toPublic(req.user!) } });
  }

  public static async updateMe(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(updateProfileSchema, req.body);
    const user = await UserService.updateName(req.user!._id.toString(), input);
    res.status(200).json({ success: true, message: 'Profile updated', data: { user } });
  }

  public static async changePassword(req: Request, res: Response): Promise<void> {
    const input = parseOrThrow(changePasswordSchema, req.body);
    await UserService.changePassword(req.user!._id.toString(), input);
    res.status(200).json({ success: true, message: 'Password changed' });
  }
}
