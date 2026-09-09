import { Router } from "express";

import { authenticate } from "../../middlewares/auth.middleware.js";
import { validate } from "../../middlewares/validate.middleware.js";

import {
  getMyFeedbackController,
  upsertFeedbackController,
} from "./feedback.controller.js";
import {
  messageIdParamSchema,
  upsertFeedbackSchema,
} from "./feedback.validation.js";

const router = Router();

router.post(
  "/:messageId/feedback",
  authenticate,
  validate(messageIdParamSchema, "params"),
  validate(upsertFeedbackSchema),
  upsertFeedbackController,
);

router.get(
  "/:messageId/feedback",
  authenticate,
  validate(messageIdParamSchema, "params"),
  getMyFeedbackController,
);

export default router;
