import { Request, Response } from 'express';
import { AppError } from '../middlewares/error.middleware';
import { ImportService } from '../service/import.service';

export class ImportController {
  public static async template(_req: Request, res: Response): Promise<void> {
    const data = await ImportService.buildTemplate();
    res.status(200).json({ success: true, data });
  }

  public static async importProducts(req: Request, res: Response): Promise<void> {
    if (typeof req.body !== 'string') throw new AppError('Send the CSV file as text/csv', 400, 'CSV_REQUIRED');
    const { created } = await ImportService.importCsv(req.body);
    res.status(201).json({ success: true, message: `Imported ${created} products`, data: { created } });
  }
}
