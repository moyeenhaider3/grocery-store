import mongoose from 'mongoose';
import { env } from '../config/env';
import { User, UserRole } from '../models/user.model';
import { UserService } from '../service/user.service';
import { parseOrThrow, signupSchema } from '../validation/auth.schemas';

// Idempotent: never modifies an existing account. Never prints the password.
async function main(): Promise<void> {
  const values: Record<string, string> = {};
  for (const key of ['ADMIN_NAME', 'ADMIN_EMAIL', 'ADMIN_PASSWORD']) {
    const value = process.env[key];
    if (!value) {
      throw new Error(`Missing ${key}. Set ADMIN_NAME, ADMIN_EMAIL and ADMIN_PASSWORD in backend/.env or the shell.`);
    }
    values[key] = value;
  }

  const parsed = parseOrThrow(signupSchema, {
    name: values.ADMIN_NAME,
    email: values.ADMIN_EMAIL,
    password: values.ADMIN_PASSWORD,
  });

  await mongoose.connect(env.mongoUri);
  await User.init();

  const existing = await User.findOne({ email: parsed.email });
  if (existing) {
    console.log(`Admin already exists: ${parsed.email} (role ${existing.role}), nothing changed`);
  } else {
    await UserService.createUser({ ...parsed, role: UserRole.ADMIN });
    console.log(`Admin created: ${parsed.email}`);
  }

  await mongoose.disconnect();
}

main().then(
  () => process.exit(0),
  (e) => {
    console.error(e instanceof Error ? e.message : e);
    process.exit(1);
  }
);
