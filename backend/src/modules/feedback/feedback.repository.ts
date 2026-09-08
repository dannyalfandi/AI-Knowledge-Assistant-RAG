import prisma from "../../config/database.js";

import type { UpsertFeedbackInput } from "./feedback.validation.js";

const feedbackSelect = {
  id: true,
  messageId: true,
  type: true,
  comment: true,
  createdAt: true,
  updatedAt: true,
} as const;

/**
 * Loads a message only if it belongs to a conversation owned by `userId`.
 * Returns `null` when the message does not exist or is in someone else's
 * conversation, so the caller can answer 404 without leaking existence.
 */
export async function findMessageForUser(messageId: string, userId: string) {
  return prisma.message.findFirst({
    where: { id: messageId, conversation: { userId } },
    select: { id: true, role: true },
  });
}

export async function findFeedback(userId: string, messageId: string) {
  return prisma.feedback.findUnique({
    where: { userId_messageId: { userId, messageId } },
    select: feedbackSelect,
  });
}

export async function upsertFeedback(
  userId: string,
  messageId: string,
  input: { type: UpsertFeedbackInput["type"]; comment: string | null },
) {
  return prisma.feedback.upsert({
    where: { userId_messageId: { userId, messageId } },
    create: {
      userId,
      messageId,
      type: input.type,
      comment: input.comment,
    },
    update: {
      type: input.type,
      comment: input.comment,
    },
    select: feedbackSelect,
  });
}
