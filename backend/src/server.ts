import http from 'http';
import app from './app';
import { env } from './config/env';
import { connectDatabase } from './config/db';

// Express 5 passes listen errors (e.g. EADDRINUSE) to this callback instead of throwing
const server: http.Server = app.listen(env.port, (error?: Error): void => {
  if (error) {
    console.error(`❌ Failed to start server on port ${env.port}:`, error.message);
    process.exit(1);
  }
  console.log(`🚀 Server running in [${env.nodeEnv}] mode on port ${env.port}`);
});

// Guard against unhandled Promise rejections (e.g., future database connection failures)
process.on('unhandledRejection', (reason: unknown): void => {
  console.error('💥 UNHANDLED REJECTION! Shutting down server gracefully...');
  console.error(reason);

  server.close((): void => {
    process.exit(1);
  });
});

// Guard against uncaught synchronous exceptions
process.on('uncaughtException', (error: Error): void => {
  console.error('💥 UNCAUGHT EXCEPTION! Shutting down immediately...');
  console.error(error);
  process.exit(1);
});

// Keep the HTTP server (including /health) available if MongoDB is not ready.
void connectDatabase().catch((error: unknown): void => {
  console.error('❌ MongoDB Connection Error:', error);
});

