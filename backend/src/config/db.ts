import mongoose from 'mongoose';
import { env } from './env';

/**
 * Connects to MongoDB using Mongoose.
 * Exits the process if connection fails on startup.
 */
export const connectDatabase = async (): Promise<void> => {
  const connection = await mongoose.connect(env.mongoUri);
  console.log(`🍃 MongoDB Connected: ${connection.connection.host}`);
};