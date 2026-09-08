import {
  generateEmbedding,
  getEmbeddingProvider,
} from "../ai/embedding/embedding.service.js";
import {
  findDocumentChunks,
  upsertDocumentChunkEmbedding,
} from "./document.repository.js";

export async function indexDocumentChunks(documentId: string) {
  const chunks = await findDocumentChunks(documentId);

  if (chunks.length === 0) {
    throw new Error("Document has no chunks to index");
  }

  const provider = getEmbeddingProvider();

  let indexedCount = 0;

  for (const chunk of chunks) {
    const embedding = await generateEmbedding(chunk.content, "passage");

    await upsertDocumentChunkEmbedding(chunk.id, {
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
