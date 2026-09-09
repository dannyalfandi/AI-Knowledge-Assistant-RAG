import type { Response } from "express";

import {
  requireUserId,
  type AuthenticatedRequest,
} from "../../middlewares/auth.middleware.js";
import * as feedbackService from "./feedback.service.js";
import type {
  MessageIdParam,
  UpsertFeedbackInput,
} from "./feedback.validation.js";

function messageId(req: AuthenticatedRequest): string {
  return (req.params as unknown as MessageIdParam).messageId;
}

export async function upsertFeedbackController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const data = await feedbackService.upsertFeedback(
    requireUserId(req),
    messageId(req),
    req.body as UpsertFeedbackInput,
  );

  return res.status(200).json({ data });
}

export async function getMyFeedbackController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const data = await feedbackService.getMyFeedback(
    requireUserId(req),
    messageId(req),
  );

  return res.status(200).json({ data });
}
