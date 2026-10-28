import { Router } from 'express';
import { authenticate } from '../middlewares/auth.middleware';
import { CartController } from '../controllers/cart.controller';

// Authenticated for every role: admins and customers both have carts.
const cartRouter: Router = Router();
cartRouter.use(authenticate);

cartRouter.get('/', CartController.get);
cartRouter.post('/items', CartController.addItem);
cartRouter.patch('/items/:productId', CartController.updateItem);
cartRouter.delete('/items/:productId', CartController.removeItem);

export default cartRouter;
