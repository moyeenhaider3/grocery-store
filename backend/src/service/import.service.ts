import { Types } from 'mongoose';
import { AppError } from '../middlewares/error.middleware';
import { Category, categoryKey } from '../models/category.model';
import { Product } from '../models/product.model';
import { productInputSchema } from '../validation/catalog.schemas';
import { parseCsv, toCsvRow } from '../utils/csv';

export const IMPORT_COLUMNS = ['name', 'description', 'price', 'stock', 'category', 'imageUrl', 'isActive'] as const;

export const MAX_IMPORT_ROWS = 500;
const REQUIRED_COLUMNS = ['name', 'price', 'stock', 'category'];

type RowError = { row: number; column: string; message: string };

export class ImportService {
  /** Validate every row with the create rules; insert all or none. Create-only (D-18). */
  public static async importCsv(text: string): Promise<{ created: number }> {
    const records = parseCsv(text);
    if (records.length === 0) throw new AppError('The file has no data rows', 400, 'CSV_EMPTY');

    // Header: trimmed, case-insensitive match against the known columns.
    const byLower = new Map<string, string>(IMPORT_COLUMNS.map((c) => [c.toLowerCase(), c]));
    const header: string[] = [];
    const unknown: string[] = [];
    const duplicate: string[] = [];
    for (const raw of records[0]) {
      const name = byLower.get(raw.trim().toLowerCase());
      if (!name) unknown.push(raw.trim() || '(blank)');
      else if (header.includes(name)) duplicate.push(name);
      header.push(name ?? raw);
    }
    const missing = REQUIRED_COLUMNS.filter((c) => !header.includes(c));
    if (missing.length) throw new AppError(`Missing column(s): ${missing.join(', ')}`, 400, 'CSV_INVALID_HEADER');
    if (unknown.length) throw new AppError(`Unknown column(s): ${unknown.join(', ')}`, 400, 'CSV_INVALID_HEADER');
    if (duplicate.length) throw new AppError(`Duplicate column(s): ${duplicate.join(', ')}`, 400, 'CSV_INVALID_HEADER');

    // Header is row 1; blank records are skipped but still counted.
    const rows = records
      .slice(1)
      .map((fields, i) => ({ row: i + 2, fields }))
      .filter((r) => r.fields.some((f) => f.trim() !== ''));
    if (rows.length === 0) throw new AppError('The file has no data rows', 400, 'CSV_EMPTY');
    if (rows.length > MAX_IMPORT_ROWS) {
      throw new AppError(
        `The file has ${rows.length} data rows; the limit is ${MAX_IMPORT_ROWS}`,
        400,
        'CSV_TOO_MANY_ROWS',
      );
    }

    const categories = new Map<string, Types.ObjectId>();
    for (const c of await Category.find()) categories.set(c.nameKey, c._id);

    const errors: RowError[] = [];
    const docs: Array<Record<string, unknown> & { _id: Types.ObjectId }> = [];
    for (const { row, fields } of rows) {
      if (fields.length !== header.length) {
        errors.push({ row, column: 'row', message: `Expected ${header.length} values, found ${fields.length}` });
        continue;
      }
      const cell = (col: string): string => (fields[header.indexOf(col)] ?? '').trim();
      const rowErrors: RowError[] = [];
      const fail = (column: string, message: string): void => {
        rowErrors.push({ row, column, message });
      };

      // price: rupee text -> integer paise with integer maths only
      let price = 0;
      const priceText = cell('price');
      if (/^\d{1,8}(\.\d{1,2})?$/.test(priceText)) {
        const [whole, frac = ''] = priceText.split('.');
        price = Number(whole) * 100 + Number(frac.padEnd(2, '0'));
      }
      if (price <= 0) fail('price', 'Price must be a rupee amount above 0 with at most 2 decimals, e.g. 1299.00');

      const stockText = cell('stock');
      const stock = /^\d+$/.test(stockText) ? Number(stockText) : NaN;
      if (Number.isNaN(stock)) fail('stock', 'Stock must be a whole number 0 or more');

      const catId = categories.get(categoryKey(cell('category')));
      if (!catId) fail('category', `Unknown category "${cell('category')}". Create it first or use an existing name`);

      let isActive = true;
      const flag = header.includes('isActive') ? cell('isActive').toLowerCase() : '';
      if (flag === '') isActive = true;
      else if (['true', 'yes', '1'].includes(flag)) isActive = true;
      else if (['false', 'no', '0'].includes(flag)) isActive = false;
      else fail('isActive', 'isActive must be true or false');

      const parsed = productInputSchema.safeParse({
        name: cell('name'),
        description: header.includes('description') ? cell('description') : '',
        price,
        stock: Number.isNaN(stock) ? 0 : stock,
        category: catId ? String(catId) : '',
        imageUrl: header.includes('imageUrl') ? cell('imageUrl') : '',
        isActive,
      });
      if (!parsed.success) {
        for (const issue of parsed.error.issues) {
          const column = String(issue.path[0] ?? 'row');
          if (!rowErrors.some((e) => e.column === column)) fail(column, issue.message);
        }
      }

      if (rowErrors.length) errors.push(...rowErrors);
      else if (parsed.success) docs.push({ ...parsed.data, _id: new Types.ObjectId() });
    }

    if (errors.length) {
      errors.sort((a, b) => a.row - b.row);
      const k = new Set(errors.map((e) => e.row)).size;
      throw new AppError(`${k} row(s) have errors. Nothing was imported.`, 400, 'CSV_VALIDATION_FAILED', errors);
    }

    // No transaction needed (standalone mongod): compensate if the bulk insert fails midway.
    const ids = docs.map((d) => d._id);
    try {
      await Product.insertMany(docs, { ordered: true });
    } catch (err) {
      await Product.deleteMany({ _id: { $in: ids } });
      throw err;
    }
    return { created: docs.length };
  }

  public static async buildTemplate(): Promise<{ csv: string; columns: string[]; categories: string[] }> {
    const docs = await Category.find().sort({ nameKey: 1 });
    const categories = docs.map((c) => c.name);
    const rows: string[] = [toCsvRow([...IMPORT_COLUMNS])];
    // Categories are never invented: with none, only the header row is returned.
    if (categories.length > 0) {
      rows.push(toCsvRow(['Sample Cotton T-Shirt', 'Soft cotton, regular fit', '499.00', '25', categories[0], '', 'true']));
      rows.push(
        toCsvRow(['Sample Ceramic Mug', '', '249.50', '0', categories[1] ?? categories[0], 'https://example.com/images/mug.jpg', 'false']),
      );
    }
    return { csv: rows.join('\r\n') + '\r\n', columns: [...IMPORT_COLUMNS], categories };
  }
}
