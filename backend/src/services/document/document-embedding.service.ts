import crypto from "node:crypto";

import prisma from "../../config/database.js";

export interface ChunkEmbeddingInput {
  embedding: number[];
  provider: string;
  model: string;
  dimensions: number;
}

export async function saveDocumentChunkEmbedding(
  chunkId: string,
  input: ChunkEmbeddingInput,
) {
  const vector = `[${input.embedding.join(",")}]`;

  await prisma.$executeRawUnsafe(
    `
      INSERT INTO document_chunk_embeddings
        (id, "documentChunkId", provider, model, dimensions, embedding, created_at, updated_at)
      VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6::vector, now(), now())
      ON CONFLICT ("documentChunkId", provider, model)
      DO UPDATE SET
        embedding = EXCLUDED.embedding,
        dimensions = EXCLUDED.dimensions,
        updated_at = now()
    `,
    crypto.randomUUID(),
    chunkId,
    input.provider,
    input.model,
    input.dimensions,
    vector,
  );
}
