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

/** The citation row shape `findConversationWithMessages` selects. */
interface StoredSource {
  similarityScore: number;
  documentChunk: {
    id: string;
    content: string;
    chunkIndex: number;
    pageNumber: number | null;
    document: { id: string; originalName: string };
  };
}

/**
 * Flattens a stored citation row into the same shape `/ask` returns, so a
 * client renders sources identically whether the answer just arrived or the
 * conversation was reopened later.
 */
function toSourcePayload(source: StoredSource) {
  return {
    documentChunkId: source.documentChunk.id,
    documentId: source.documentChunk.document.id,
    documentName: source.documentChunk.document.originalName,
    pageNumber: source.documentChunk.pageNumber,
    chunkIndex: source.documentChunk.chunkIndex,
    content: source.documentChunk.content,
    similarityScore: source.similarityScore,
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

  return {
    ...conversation,
    messages: conversation.messages.map((message) => ({
      id: message.id,
      role: message.role,
      content: message.content,
      createdAt: message.createdAt,
      sources: message.sources.map(toSourcePayload),
      // Unique per (userId, messageId) and already filtered to this reader, so
      // there is at most one row; exposed as a single object rather than a
      // list the client would have to unwrap.
      myFeedback: message.feedbacks[0] ?? null,
    })),
  };
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
