import { Router } from 'express';
import { authenticate } from '../middlewares/auth.middleware';
import { OrderController } from '../controllers/order.controller';

// Any logged-in, non-blocked user (admins included) can place and view their own orders.
const orderRouter: Router = Router();
orderRouter.use(authenticate);

orderRouter.post('/', OrderController.place);
orderRouter.get('/', OrderController.listMine);
orderRouter.get('/:id', OrderController.getMine);
orderRouter.post('/:id/cancel', OrderController.cancelMine);

export default orderRouter;
