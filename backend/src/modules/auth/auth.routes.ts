import { Router } from "express";

import { validate } from "../../middlewares/validate.middleware.js";

import { loginController } from "./auth.controller.js";
import { loginSchema } from "./auth.validation.js";

const router = Router();

router.post("/login", validate(loginSchema), loginController);

export default router;
