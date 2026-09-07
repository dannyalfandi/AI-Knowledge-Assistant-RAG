import { z } from "zod";

export const createConversationSchema = z.object({
  title: z.string().trim().min(1).max(200).optional(),
});

export const listConversationsSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const conversationIdParamSchema = z.object({
  id: z.uuid(),
});

export const createMessageSchema = z.object({
  content: z.string().trim().min(1),
});

export type CreateConversationInput = z.infer<typeof createConversationSchema>;
export type ListConversationsQuery = z.infer<typeof listConversationsSchema>;
export type ConversationIdParam = z.infer<typeof conversationIdParamSchema>;
export type CreateMessageInput = z.infer<typeof createMessageSchema>;
