import { z } from "zod";

export const documentIdSchema = z.object({
  id: z.uuid(),
});

export type DocumentIdInput = z.infer<typeof documentIdSchema>;
