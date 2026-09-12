import { BadRequestError, NotFoundError } from "../../utils/errors.js";
import * as feedbackRepository from "./feedback.repository.js";
import type { UpsertFeedbackInput } from "./feedback.validation.js";

async function assertAssistantMessageForUser(messageId: string, userId: string) {
  const message = await feedbackRepository.findMessageForUser(messageId, userId);

  if (!message) {
    throw new NotFoundError("Message not found");
  }

  if (message.role !== "ASSISTANT") {
    throw new BadRequestError("Feedback hanya untuk jawaban AI");
  }
}

export async function upsertFeedback(
  userId: string,
  messageId: string,
  input: UpsertFeedbackInput,
) {
  await assertAssistantMessageForUser(messageId, userId);

  // `comment` stays undefined when the request omitted it, which leaves any
  // existing comment untouched — a thumbs-up/down toggle carries the type only.
  return feedbackRepository.upsertFeedback(userId, messageId, {
    type: input.type,
    comment: input.comment,
  });
}

export async function getMyFeedback(userId: string, messageId: string) {
  await assertAssistantMessageForUser(messageId, userId);

  const feedback = await feedbackRepository.findFeedback(userId, messageId);

  if (!feedback) {
    throw new NotFoundError("Feedback not found");
  }

  return feedback;
}
