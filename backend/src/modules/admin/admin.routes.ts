import { Router } from "express";

import { authenticate } from "../../middlewares/auth.middleware.js";
import { authorize } from "../../middlewares/role.middleware.js";

import { getDashboardController } from "./admin.controller.js";

const router = Router();

router.get(
  "/dashboard",
  authenticate,
  authorize("ADMIN"),
  getDashboardController,
);

export default router;
