import type { Request, Response } from "express";

import { login } from "./auth.service.js";
import type { LoginInput } from "./auth.validation.js";

export async function loginController(req: Request, res: Response) {
  const data = await login(req.body as LoginInput);

  return res.status(200).json({ data });
}
