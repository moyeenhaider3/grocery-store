import { AppError } from '../middlewares/error.middleware';

// Minimal RFC 4180 writer. A field is quoted when it contains , " CR or LF.
export const toCsvRow = (fields: string[]): string =>
  fields.map((f) => (/[",\r\n]/.test(f) ? `"${f.replace(/"/g, '""')}"` : f)).join(',');

// RFC 4180 reader: quoted fields, "" escapes, commas/newlines inside quotes, CRLF/LF/CR, BOM.
export const parseCsv = (input: string): string[][] => {
  const text = input.charCodeAt(0) === 0xfeff ? input.slice(1) : input;
  const records: string[][] = [];
  let record: string[] = [];
  let field = '';
  let inQuotes = false;
  let quoteOpenedAt = 0;
  let pending = false; // true when the current record has any content or separator

  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (inQuotes) {
      if (ch === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field += ch;
      }
      continue;
    }
    if (ch === '"' && field === '') {
      inQuotes = true;
      quoteOpenedAt = records.length + 1;
      pending = true;
    } else if (ch === ',') {
      record.push(field);
      field = '';
      pending = true;
    } else if (ch === '\n' || ch === '\r') {
      if (ch === '\r' && text[i + 1] === '\n') i++;
      record.push(field);
      records.push(record);
      record = [];
      field = '';
      pending = false;
    } else {
      field += ch;
      pending = true;
    }
  }
  if (inQuotes) throw new AppError(`Row ${quoteOpenedAt}: unclosed quote`, 400, 'CSV_PARSE_ERROR');
  if (pending || field !== '') {
    record.push(field);
    records.push(record);
  }
  return records;
};
