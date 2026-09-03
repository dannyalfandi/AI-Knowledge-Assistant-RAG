import type { Request, Response } from "express";

import { login } from "./auth.service.js";
import { loginSchema } from "./auth.validation.js";

export async function loginController(req: Request, res: Response) {
  const result = loginSchema.safeParse(req.body);

  if (!result.success) {
    return res.status(400).json({
      message: "Invalid request",
      errors: result.error.flatten(),
    });
  }

  try {
    const data = await login(result.data);

    return res.status(200).json(data);
  } catch (error) {
    if (
      error instanceof Error &&
      (error.message === "Invalid email or password" ||
        error.message === "User account is inactive")
    ) {
      return res.status(401).json({
        message: error.message,
      });
    }

    console.error("Login error:", error);

    return res.status(500).json({
      message: "Internal server error",
    });
  }
}
