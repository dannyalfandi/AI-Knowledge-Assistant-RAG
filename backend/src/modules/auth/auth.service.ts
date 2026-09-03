import argon2 from "argon2";
import jwt from "jsonwebtoken";
import type { SignOptions } from "jsonwebtoken";

import prisma from "../../config/database.js";
import { env } from "../../config/env.js";
import type { LoginInput } from "./auth.validation.js";

export async function login(input: LoginInput) {
  const user = await prisma.user.findUnique({
    where: {
      email: input.email,
    },
    include: {
      role: true,
    },
  });

  if (!user) {
    throw new Error("Invalid email or password");
  }

  if (!user.isActive) {
    throw new Error("User account is inactive");
  }

  const passwordValid = await argon2.verify(user.passwordHash, input.password);

  if (!passwordValid) {
    throw new Error("Invalid email or password");
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
