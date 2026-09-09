import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middlewares/auth.middleware.js";
import * as adminService from "./admin.service.js";

export async function getDashboardController(
  _req: AuthenticatedRequest,
  res: Response,
) {
  const data = await adminService.getDashboard();

  return res.status(200).json({ data });
}
