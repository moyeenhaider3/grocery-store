import bcrypt from 'bcryptjs';
import { User, IUserDocument, UserRole } from '../models/user.model';
import { AppError } from '../middlewares/error.middleware';
import { signToken } from '../utils/jwt';
import { UserService, IPublicUser } from './user.service';
import { parseOrThrow, signupSchema, loginSchema } from '../validation/auth.schemas';

export interface IAuthResponse {
  user: IPublicUser;
  token: string;
}

// Compared against when the email is unknown so response time does not reveal registered emails.
const DUMMY_HASH = bcrypt.hashSync('timing-equalizer-not-a-real-password', 12);

export class AuthService {
  public static async signup(body: unknown): Promise<IAuthResponse> {
    const parsed = parseOrThrow(signupSchema, body);

    // Public signup always creates a USER; any `role` in the body is ignored.
    const user = await UserService.createUser({ ...parsed, role: UserRole.USER });

    return { user: UserService.toPublic(user), token: signToken({ userId: user._id.toString() }) };
  }

  public static async login(body: unknown): Promise<IAuthResponse> {
    const { email, password } = parseOrThrow(loginSchema, body);

    const user = await User.findOne({ email }).select('+passwordHash');
    const isPasswordValid = await bcrypt.compare(password, user ? user.passwordHash : DUMMY_HASH);

    if (!user || !isPasswordValid) {
      throw new AppError('Invalid email or password', 401, 'INVALID_CREDENTIALS');
    }
    // Only revealed after a correct password.
    if (user.isBlocked) {
      throw new AppError('Your account has been blocked', 403, 'ACCOUNT_BLOCKED');
    }

    return { user: UserService.toPublic(user), token: signToken({ userId: user._id.toString() }) };
  }

  public static getMe(user: IUserDocument): IPublicUser {
    return UserService.toPublic(user);
  }
}
