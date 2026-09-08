import { z } from "zod";

export const searchQuerySchema = z.object({
  query: z.string().trim().min(1).max(1000),
  topK: z.coerce.number().int().min(1).max(20).default(5),
});

export type SearchQueryInput = z.infer<typeof searchQuerySchema>;
