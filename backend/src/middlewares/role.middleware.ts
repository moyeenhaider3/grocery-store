import { Request, Response, NextFunction } from 'express';
import { UserRole } from '../models/user.model';
import { AppError } from './error.middleware';

/**
 * Middleware factory to restrict access to specific roles.
 * Example usage: restrictTo(UserRole.ADMIN)
 */
export const restrictTo = (...allowedRoles: UserRole[]) => {
    return (req: Request, res: Response, next: NextFunction): void => {
        // req.user is guaranteed to exist if 'authenticate' middleware ran before this
        if (!req.user || !allowedRoles.includes(req.user.role)) {
            throw new AppError(
                'You do not have permission to perform this action',
                403,
                'FORBIDDEN'
            );
        }
        next();
    };
};