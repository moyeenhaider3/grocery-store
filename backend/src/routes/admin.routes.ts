import express, { Request, Response, Router } from 'express';
import { authenticate } from '../middlewares/auth.middleware';
import { restrictTo } from '../middlewares/role.middleware';
import { UserRole } from '../models/user.model';
import { UserService } from '../service/user.service';
import { CategoryController } from '../controllers/category.controller';
import { ProductController } from '../controllers/product.controller';
import { AdminOrderController } from '../controllers/admin-order.controller';
import { AdminUserController } from '../controllers/admin-user.controller';
import { AdminStatsController } from '../controllers/admin-stats.controller';
import { ImportController } from '../controllers/import.controller';

// Every admin endpoint mounts on this router, behind the single gate below.
const adminRouter: Router = Router();

adminRouter.use(authenticate, restrictTo(UserRole.ADMIN));

adminRouter.get('/ping', (req: Request, res: Response): void => {
  res.status(200).json({ success: true, data: { admin: true, user: UserService.toPublic(req.user!) } });
});

adminRouter.get('/stats', AdminStatsController.get);

adminRouter.get('/categories', CategoryController.list);
adminRouter.post('/categories', CategoryController.create);
adminRouter.patch('/categories/:id', CategoryController.rename);
adminRouter.delete('/categories/:id', CategoryController.remove);
adminRouter.get('/products', ProductController.list);
adminRouter.get('/products/import/template', ImportController.template);
adminRouter.post(
  '/products/import',
  express.text({ type: ['text/csv', 'text/plain'], limit: '1mb' }),
  ImportController.importProducts,
);
adminRouter.post('/products', ProductController.create);
adminRouter.get('/products/:id', ProductController.get);
adminRouter.put('/products/:id', ProductController.update);
adminRouter.get('/orders', AdminOrderController.list);
adminRouter.get('/orders/:id', AdminOrderController.get);
adminRouter.patch('/orders/:id/status', AdminOrderController.updateStatus);
adminRouter.get('/users', AdminUserController.list);
adminRouter.post('/users', AdminUserController.create);
adminRouter.patch('/users/:id/role', AdminUserController.setRole);
adminRouter.patch('/users/:id/block', AdminUserController.setBlocked);

export default adminRouter;
