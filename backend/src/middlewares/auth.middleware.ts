import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';
import { User } from '../models/user.model';
import { AppError } from './error.middleware';

/**
 * Protects routes: Bearer token only, user (and role) reloaded from the DB on every request.
 */
export const authenticate = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const header = req.headers.authorization;
  const token = header && header.startsWith('Bearer ') ? header.slice(7).trim() : undefined;

  if (!token) {
    throw new AppError('You are not logged in. Please log in to gain access.', 401, 'UNAUTHORIZED');
  }

  let payload;
  try {
    payload = verifyToken(token);
  } catch {
    throw new AppError('Invalid or expired authentication token', 401, 'INVALID_TOKEN');
  }

  const user = await User.findById(payload.userId);
  if (!user) {
    throw new AppError('The user belonging to this token no longer exists', 401, 'USER_DELETED');
  }
  if (user.isBlocked) {
    throw new AppError('Your account has been blocked', 403, 'ACCOUNT_BLOCKED');
  }

  req.user = user;
  next();
};
