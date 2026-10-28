import { Request, Response, NextFunction } from 'express';

/**
 * Middleware that logs the timestamp, HTTP method, and URL of every request.
 */
export const requestLogger = (req: Request, res: Response, next: NextFunction): void => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.originalUrl}`);

  // Call next() to pass the request to the next handler in the pipeline
  next();
};
