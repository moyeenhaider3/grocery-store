import { Router } from 'express';
import { authenticate } from '../middlewares/auth.middleware';
import { UserController } from '../controllers/user.controller';

// Only ever touches the authenticated user; no route takes a user id.
const userRouter: Router = Router();
userRouter.use(authenticate);

userRouter.get('/me', UserController.getMe);
userRouter.patch('/me', UserController.updateMe);
userRouter.patch('/me/password', UserController.changePassword);

export default userRouter;
