import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middlewares/auth.middleware.js";
import { UnauthorizedError } from "../../utils/errors.js";
import * as conversationRagService from "./conversation.rag.service.js";
import * as conversationService from "./conversation.service.js";
import type {
  AskInput,
  ConversationIdParam,
  CreateConversationInput,
  CreateMessageInput,
  ListConversationsQuery,
} from "./conversation.validation.js";

function requireUserId(req: AuthenticatedRequest): string {
  if (!req.user) {
    throw new UnauthorizedError();
  }

  return req.user.id;
}

function conversationId(req: AuthenticatedRequest): string {
  return (req.params as unknown as ConversationIdParam).id;
}

export async function createConversationController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const data = await conversationService.createConversation(
    requireUserId(req),
    req.body as CreateConversationInput,
  );

  return res.status(201).json({ data });
}

export async function listConversationsController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const { data, pagination } = await conversationService.listConversations(
    requireUserId(req),
    req.query as unknown as ListConversationsQuery,
  );

  return res.status(200).json({ data, pagination });
}

export async function getConversationController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const data = await conversationService.getConversation(
    requireUserId(req),
    conversationId(req),
  );

  return res.status(200).json({ data });
}

export async function deleteConversationController(
  req: AuthenticatedRequest,
  res: Response,
) {
  await conversationService.deleteConversation(
    requireUserId(req),
    conversationId(req),
  );

  return res.status(204).send();
}

export async function createMessageController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const data = await conversationService.addUserMessage(
    requireUserId(req),
    conversationId(req),
    req.body as CreateMessageInput,
  );

  return res.status(201).json({ data });
}

export async function askController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const data = await conversationRagService.askInConversation(
    requireUserId(req),
    conversationId(req),
    req.body as AskInput,
  );

  return res.status(201).json({ data });
}
