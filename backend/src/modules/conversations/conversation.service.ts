import { NotFoundError } from "../../utils/errors.js";
import {
  buildPaginationMeta,
  toSkipTake,
  type PaginationMeta,
} from "../../utils/pagination.js";
import * as conversationRepository from "./conversation.repository.js";
import type {
  CreateConversationInput,
  CreateMessageInput,
  ListConversationsQuery,
} from "./conversation.validation.js";

export async function createConversation(
  userId: string,
  input: CreateConversationInput,
) {
  return conversationRepository.createConversation(userId, input.title ?? null);
}

type ConversationSummary = Awaited<
  ReturnType<typeof conversationRepository.listConversations>
>[number];

export async function listConversations(
  userId: string,
  query: ListConversationsQuery,
): Promise<{ data: ConversationSummary[]; pagination: PaginationMeta }> {
  const [data, total] = await Promise.all([
    conversationRepository.listConversations(userId, toSkipTake(query)),
    conversationRepository.countConversations(userId),
  ]);

  return {
    data,
    pagination: buildPaginationMeta(total, query),
  };
}

export async function getConversation(userId: string, conversationId: string) {
  const conversation =
    await conversationRepository.findConversationWithMessages(
      conversationId,
      userId,
    );

  if (!conversation) {
    throw new NotFoundError("Conversation not found");
  }

  return conversation;
}

export async function deleteConversation(
  userId: string,
  conversationId: string,
) {
  const deleted = await conversationRepository.deleteConversationForUser(
    conversationId,
    userId,
  );

  if (deleted === 0) {
    throw new NotFoundError("Conversation not found");
  }
}

export async function addUserMessage(
  userId: string,
  conversationId: string,
  input: CreateMessageInput,
) {
  const conversation = await conversationRepository.findConversationForUser(
    conversationId,
    userId,
  );

  if (!conversation) {
    throw new NotFoundError("Conversation not found");
  }

  return conversationRepository.createUserMessage(conversationId, input.content);
}
