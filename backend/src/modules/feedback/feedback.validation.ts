import { z } from "zod";

export const messageIdParamSchema = z.object({
  messageId: z.uuid(),
});

export const upsertFeedbackSchema = z.object({
  type: z.enum(["POSITIVE", "NEGATIVE"]),
  comment: z.string().trim().min(1).max(1000).optional(),
});

export type MessageIdParam = z.infer<typeof messageIdParamSchema>;
export type UpsertFeedbackInput = z.infer<typeof upsertFeedbackSchema>;
