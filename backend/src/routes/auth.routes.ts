import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticate } from '../middlewares/auth.middleware';

const authRouter: Router = Router();

// Public routes
authRouter.post('/signup', AuthController.signup);
authRouter.post('/login', AuthController.login);

// Protected routes (require authenticate middleware)
authRouter.post('/logout', authenticate, AuthController.logout);
authRouter.get('/me', authenticate, AuthController.getMe);

export default authRouter;