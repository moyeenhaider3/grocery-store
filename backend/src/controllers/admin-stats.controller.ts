import { Request, Response } from 'express';
import { StatsService } from '../service/stats.service';

// Admin access is enforced by the router gate (authenticate + restrictTo ADMIN).
export class AdminStatsController {
  public static async get(_req: Request, res: Response): Promise<void> {
    const stats = await StatsService.dashboard();
    res.status(200).json({ success: true, data: { stats } });
  }
}
