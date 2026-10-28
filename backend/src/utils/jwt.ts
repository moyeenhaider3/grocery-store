import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';

// Payload carries only the user id; role and blocked state are read from the DB per request.
export interface ITokenPayload {
  userId: string;
}

export const signToken = (payload: ITokenPayload): string => {
  const options: SignOptions = {
    algorithm: 'HS256',
    expiresIn: env.jwtExpiresIn as SignOptions['expiresIn'],
  };
  return jwt.sign(payload, env.jwtSecret, options);
};

export const verifyToken = (token: string): ITokenPayload => {
  return jwt.verify(token, env.jwtSecret, { algorithms: ['HS256'] }) as ITokenPayload;
};
