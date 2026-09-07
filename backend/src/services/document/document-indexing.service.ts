import prisma from "../../config/database.js";
import {
  generateEmbedding,
  getEmbeddingProvider,
} from "../ai/embedding/embedding.service.js";
import { saveDocumentChunkEmbedding } from "./document-embedding.service.js";

export async function indexDocumentChunks(documentId: string) {
  const chunks = await prisma.documentChunk.findMany({
    where: {
      documentId,
    },
    orderBy: {
      chunkIndex: "asc",
    },
  });

  if (chunks.length === 0) {
    throw new Error("Document has no chunks to index");
  }

  const provider = getEmbeddingProvider();

  let indexedCount = 0;

  for (const chunk of chunks) {
    const embedding = await generateEmbedding(chunk.content, "passage");

    await saveDocumentChunkEmbedding(chunk.id, {
      embedding,
      provider: provider.provider,
      model: provider.model,
      dimensions: provider.dimensions,
    });

    indexedCount++;
  }

  return {
    documentId,
    indexedCount,
  };
}
