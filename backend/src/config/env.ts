import 'dotenv/config';

const isProduction = process.env.NODE_ENV === 'production';

// Absent or empty counts as missing. In production there is no silent fallback.
const required = (key: string, devDefault?: string): string => {
  const value = process.env[key];
  if (value !== undefined && value !== '') return value;
  if (isProduction || devDefault === undefined) {
    throw new Error(`Missing required env var ${key}`);
  }
  return devDefault;
};

const corsOrigins = (process.env.CORS_ORIGINS || 'http://localhost:3000')
  .split(',')
  .map((o) => o.trim().replace(/\/+$/, ''))
  .filter((o) => o.length > 0);

if (corsOrigins.includes('*')) {
  throw new Error('CORS_ORIGINS must list explicit origins');
}

interface EnvConfig {
  port: number;
  nodeEnv: string;
  mongoUri: string;
  jwtSecret: string;
  jwtExpiresIn: string;
  corsOrigins: string[];
}

export const env: EnvConfig = {
  port: Number(process.env.PORT) || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  mongoUri: required('MONGODB_URI', 'mongodb://127.0.0.1:27017/shopkart_db'),
  jwtSecret: required('JWT_SECRET', 'dev-only-secret'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  corsOrigins,
};
