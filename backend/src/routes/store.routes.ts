import { Router } from 'express';
import { StoreController } from '../controllers/store.controller';

// Public, read-only storefront endpoints (no auth).
const storeRouter: Router = Router();

storeRouter.get('/products', StoreController.listProducts);
storeRouter.get('/products/:id', StoreController.getProduct);
storeRouter.get('/categories', StoreController.listCategories);

export default storeRouter;
