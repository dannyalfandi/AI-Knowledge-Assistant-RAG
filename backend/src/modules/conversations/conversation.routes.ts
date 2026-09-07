import { Router } from "express";

import { authenticate } from "../../middlewares/auth.middleware.js";
import { validate } from "../../middlewares/validate.middleware.js";

import {
  createConversationController,
  createMessageController,
  deleteConversationController,
  getConversationController,
  listConversationsController,
} from "./conversation.controller.js";
import {
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

export default router;
