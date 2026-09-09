import crypto from "node:crypto";

import prisma from "../../config/database.js";
import type { TextChunk } from "./text-chunking.service.js";

export interface ChunkEmbeddingInput {
  embedding: number[];
  provider: string;
  model: string;
  dimensions: number;
}

/**
 * Repository for the document indexing pipeline tables (`document_chunks` and
 * `document_chunk_embeddings`). Kept as one file because the two tables are
 * written and read together on every (re-)index.
 */
export async function replaceDocumentChunks(
  documentId: string,
  chunks: TextChunk[],
) {
  await prisma.$transaction(async (tx) => {
    await tx.documentChunk.deleteMany({
      where: {
        documentId,
      },
    });

    if (chunks.length === 0) {
      return;
    }

    await tx.documentChunk.createMany({
      data: chunks.map((chunk) => ({
        documentId,
        content: chunk.content,
        chunkIndex: chunk.chunkIndex,
        pageNumber: chunk.pageNumber,
        tokenCount: chunk.tokenCount,
      })),
    });
  });
}

export async function findDocumentChunks(documentId: string) {
  return prisma.documentChunk.findMany({
    where: {
      documentId,
    },
    orderBy: {
      chunkIndex: "asc",
    },
  });
}

export async function upsertDocumentChunkEmbedding(
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
