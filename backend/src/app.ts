import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import { env } from './config/env';
import { requestLogger } from './middlewares/logger.middleware';
import { notFoundHandler, errorHandler } from './middlewares/error.middleware';
import authRouter from './routes/auth.routes';
import adminRouter from './routes/admin.routes';
import storeRouter from './routes/store.routes';
import cartRouter from './routes/cart.routes';
import orderRouter from './routes/order.routes';
import userRouter from './routes/user.routes';

const app: Application = express();

// Render terminates HTTPS at a proxy; trust the first hop.
app.set('trust proxy', 1);

// Explicit origin allowlist (Bearer-only auth, so no cross-origin auth state is needed).
// Requests without an Origin header (curl, server-to-server) are allowed through.
app.use(
  cors({
    origin: (origin, cb) => cb(null, !origin || env.corsOrigins.includes(origin)),
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

app.use(express.json({ limit: '10kb' }));
app.use(requestLogger);

app.get('/health', (req: Request, res: Response): void => {
  res.status(200).json({
    success: true,
    message: 'Server is healthy and running',
    timestamp: new Date().toISOString(),
    db: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  });
});

// API routers
app.use('/api/auth', authRouter);
app.use('/api/admin', adminRouter);
app.use('/api/cart', cartRouter);
app.use('/api/orders', orderRouter);
app.use('/api/users', userRouter);
app.use('/api', storeRouter);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
