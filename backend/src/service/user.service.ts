import bcrypt from 'bcryptjs';
import { User, IUserDocument, UserRole } from '../models/user.model';
import { AppError } from '../middlewares/error.middleware';
import {
  UpdateProfileInput,
  ChangePasswordInput,
  AdminListUsersQuery,
  AdminCreateUserInput,
  USERS_PAGE_SIZE,
} from '../validation/user.schemas';
import { assertObjectId } from '../validation/catalog.schemas';
import { escapeRegex } from './product.service';

export interface ICreateUserInput {
  name: string;
  email: string;
  password: string;
  role: UserRole;
}

export interface IPublicUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  createdAt: Date;
}

export interface IAdminUser extends IPublicUser {
  isBlocked: boolean;
}

export class UserService {
  /**
   * Hashes the password and stores a new user. Input must already be validated.
   */
  public static async createUser(input: ICreateUserInput): Promise<IUserDocument> {
    const { name, email, password, role } = input;

    if (!Object.values(UserRole).includes(role)) {
      throw new AppError(`Role must be one of: ${Object.values(UserRole).join(', ')}`, 400, 'INVALID_ROLE');
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      throw new AppError('Email is already registered', 409, 'EMAIL_ALREADY_EXISTS');
    }

    const passwordHash = await bcrypt.hash(password, 12);

    // A concurrent insert of the same email hits the unique index.
    try {
      return await User.create({ name, email, passwordHash, role });
    } catch (error: any) {
      if (error?.code === 11000) {
        throw new AppError('Email is already registered', 409, 'EMAIL_ALREADY_EXISTS');
      }
      throw error;
    }
  }

  /** Changes only the display name (PROF-02). */
  public static async updateName(userId: string, input: UpdateProfileInput): Promise<IPublicUser> {
    const user = await User.findByIdAndUpdate(
      userId,
      { $set: { name: input.name } },
      { returnDocument: 'after', runValidators: true }
    );
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }
    return UserService.toPublic(user);
  }

  /** Changes the password only when the current one matches (PROF-03). */
  public static async changePassword(userId: string, input: ChangePasswordInput): Promise<void> {
    const user = await User.findById(userId).select('+passwordHash');
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }
    // 400, not 401: the Flutter interceptor ends the session on any 401.
    const ok = await bcrypt.compare(input.currentPassword, user.passwordHash);
    if (!ok) {
      throw new AppError('Current password is incorrect', 400, 'INVALID_CURRENT_PASSWORD');
    }
    if (input.newPassword === input.currentPassword) {
      throw new AppError('New password must be different from the current password', 400, 'SAME_PASSWORD');
    }
    await User.updateOne({ _id: userId }, { $set: { passwordHash: await bcrypt.hash(input.newPassword, 12) } });
  }

  public static toPublic(user: IUserDocument): IPublicUser {
    return {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    };
  }

  public static toAdminView(user: IUserDocument): IAdminUser {
    return { ...UserService.toPublic(user), isBlocked: user.isBlocked };
  }

  /** Paged user list with optional name/email search (ADMU-01). */
  public static async listForAdmin(query: AdminListUsersQuery) {
    const { page, q } = query;
    const filter = q
      ? {
          $or: [
            { name: { $regex: escapeRegex(q), $options: 'i' } },
            { email: { $regex: escapeRegex(q), $options: 'i' } },
          ],
        }
      : {};
    const [users, total] = await Promise.all([
      User.find(filter)
        .sort({ createdAt: -1, _id: -1 })
        .skip((page - 1) * USERS_PAGE_SIZE)
        .limit(USERS_PAGE_SIZE),
      User.countDocuments(filter),
    ]);
    return {
      items: users.map((u) => UserService.toAdminView(u)),
      pagination: { total, page, limit: USERS_PAGE_SIZE, pages: Math.max(1, Math.ceil(total / USERS_PAGE_SIZE)) },
    };
  }

  /** Admin creates a user with an explicit role (ADMU-02). */
  public static async createByAdmin(input: AdminCreateUserInput): Promise<IAdminUser> {
    const user = await UserService.createUser(input);
    return UserService.toAdminView(user);
  }

  /** Change role; an admin cannot demote themselves (ADMU-03). */
  public static async setRole(actorId: string, targetId: string, role: UserRole): Promise<IAdminUser> {
    assertObjectId(targetId, 'user id');
    if (targetId === actorId && role !== UserRole.ADMIN) {
      throw new AppError('You cannot remove your own admin role', 400, 'SELF_DEMOTE_NOT_ALLOWED');
    }
    const user = await User.findByIdAndUpdate(
      targetId,
      { $set: { role } },
      { returnDocument: 'after', runValidators: true }
    );
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }
    return UserService.toAdminView(user);
  }

  /**
   * Block or unblock (ADMU-04). No token store needed: authenticate reloads the user
   * on every request, so an old token gets 403 ACCOUNT_BLOCKED next time.
   */
  public static async setBlocked(actorId: string, targetId: string, isBlocked: boolean): Promise<IAdminUser> {
    assertObjectId(targetId, 'user id');
    if (targetId === actorId && isBlocked) {
      throw new AppError('You cannot block your own account', 400, 'SELF_BLOCK_NOT_ALLOWED');
    }
    const user = await User.findByIdAndUpdate(
      targetId,
      { $set: { isBlocked } },
      { returnDocument: 'after', runValidators: true }
    );
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }
    return UserService.toAdminView(user);
  }
}
