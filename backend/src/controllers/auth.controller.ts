import { Request, Response } from 'express';
import { AuthService } from '../service/auth.service';

// Express 5 forwards rejected promises from async handlers to the error handler.
export class AuthController {
  public static async signup(req: Request, res: Response): Promise<void> {
    const data = await AuthService.signup(req.body);
    res.status(201).json({ success: true, message: 'User registered successfully', data });
  }

  public static async login(req: Request, res: Response): Promise<void> {
    const data = await AuthService.login(req.body);
    res.status(200).json({ success: true, message: 'Logged in successfully', data });
  }

  // Stateless JWT: nothing to invalidate server-side, the client drops the token.
  public static async logout(req: Request, res: Response): Promise<void> {
    res.status(200).json({ success: true, message: 'Logged out successfully' });
  }

  public static async getMe(req: Request, res: Response): Promise<void> {
    res.status(200).json({ success: true, data: { user: AuthService.getMe(req.user!) } });
  }
}
