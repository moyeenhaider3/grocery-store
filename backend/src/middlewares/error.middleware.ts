import { Request, Response, NextFunction, ErrorRequestHandler } from 'express';

/**
 * Custom error class for operational (expected) errors.
 * Example: Resource not found, duplicate alias, invalid input.
 */
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly isOperational: boolean;
  public readonly details?: unknown;

  constructor(message: string, statusCode: number, code: string = 'INTERNAL_ERROR', details?: unknown) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
    this.details = details;

    // Captures the current stack trace excluding this constructor call
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * 404 Handler for undefined routes.
 * If a request falls through all routes, this catches it and generates an AppError.
 */
export const notFoundHandler = (req: Request, res: Response, next: NextFunction): void => {
  const error = new AppError(
    `Cannot find ${req.method} ${req.originalUrl} on this server`,
    404,
    'NOT_FOUND'
  );
  next(error); // Passing an argument to next() tells Express an error occurred
};

/**
 * Global Error Handler.
 * In Express, an error handler MUST accept 4 arguments: (err, req, res, next).
 */
export const errorHandler: ErrorRequestHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Only AppErrors and body-parser's own request errors (which carry a `type`, e.g. 'entity.parse.failed')
  // are safe to report as-is. body-parser also wraps internal failures as 400s without a `type`, so
  // anything else is a server bug: report it as a 500 and keep internals out of the response.
  const isClientSafe =
    err instanceof AppError || (err.expose === true && typeof err.type === 'string');
  const statusCode = isClientSafe ? err.statusCode || err.status || 500 : 500;
  let code = isClientSafe ? err.code || err.type || 'BAD_REQUEST' : 'INTERNAL_SERVER_ERROR';
  let message = isClientSafe ? err.message : 'Something went wrong on the server';

  // body-parser size limit: say what the limit actually is (1 MB for CSV, 10 KB for JSON routes)
  if (err.type === 'entity.too.large') {
    const limit = Number(err.limit);
    const limitText = limit >= 1048576 ? '1 MB' : `${Math.round(limit / 1024)} KB`;
    code = 'PAYLOAD_TOO_LARGE';
    message = `The upload is too large. The limit is ${limitText}.`;
  }

  // Always log unexpected errors; log everything in development
  if (!isClientSafe || process.env.NODE_ENV === 'development') {
    console.error(`💥 ERROR CAUGHT BY GLOBAL HANDLER [${req.method} ${req.originalUrl}]:`, err);
  }

  const body: Record<string, unknown> = { success: false, message, code };
  if (err instanceof AppError && err.details !== undefined) body.errors = err.details;
  res.status(statusCode).json(body);
};