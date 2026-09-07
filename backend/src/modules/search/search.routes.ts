import { Router } from "express";

import { authenticate } from "../../middlewares/auth.middleware.js";
import { validate } from "../../middlewares/validate.middleware.js";

import { searchController } from "./search.controller.js";
import { searchQuerySchema } from "./search.validation.js";

const router = Router();

router.post("/", authenticate, validate(searchQuerySchema), searchController);

export default router;
