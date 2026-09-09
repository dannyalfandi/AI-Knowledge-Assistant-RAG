import argon2 from "argon2";
import jwt from "jsonwebtoken";
import type { SignOptions } from "jsonwebtoken";

import { env } from "../../config/env.js";
import { UnauthorizedError } from "../../utils/errors.js";
import * as authRepository from "./auth.repository.js";
import type { LoginInput } from "./auth.validation.js";

export async function login(input: LoginInput) {
  const user = await authRepository.findUserByEmailWithRole(input.email);

  if (!user) {
    throw new UnauthorizedError("Invalid email or password");
  }

  if (!user.isActive) {
    throw new UnauthorizedError("User account is inactive");
  }

  const passwordValid = await argon2.verify(user.passwordHash, input.password);

  if (!passwordValid) {
    throw new UnauthorizedError("Invalid email or password");
  }

  const accessToken = jwt.sign(
    {
      role: user.role.name,
    },
    env.JWT_SECRET,
    {
      subject: user.id,
      expiresIn: env.JWT_EXPIRES_IN as SignOptions["expiresIn"],
    },
  );

  return {
    accessToken,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role.name,
    },
  };
}
