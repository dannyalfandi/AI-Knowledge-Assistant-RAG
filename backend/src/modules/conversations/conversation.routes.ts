import { Router } from "express";

import { authenticate } from "../../middlewares/auth.middleware.js";
import { validate } from "../../middlewares/validate.middleware.js";

import {
  askController,
  createConversationController,
  createMessageController,
  deleteConversationController,
  getConversationController,
  listConversationsController,
} from "./conversation.controller.js";
import {
  askSchema,
  conversationIdParamSchema,
  createConversationSchema,
  createMessageSchema,
  listConversationsSchema,
} from "./conversation.validation.js";

const router = Router();

router.post(
  "/",
  authenticate,
  validate(createConversationSchema),
  createConversationController,
);

router.get(
  "/",
  authenticate,
  validate(listConversationsSchema, "query"),
  listConversationsController,
);

router.get(
  "/:id",
  authenticate,
  validate(conversationIdParamSchema, "params"),
  getConversationController,
);

router.delete(
  "/:id",
  authenticate,
  validate(conversationIdParamSchema, "params"),
  deleteConversationController,
);

router.post(
  "/:id/messages",
  authenticate,
  validate(conversationIdParamSchema, "params"),
  validate(createMessageSchema),
  createMessageController,
);

router.post(
  "/:id/ask",
  authenticate,
  validate(conversationIdParamSchema, "params"),
  validate(askSchema),
  askController,
);

export default router;
