import prisma from "../../config/database.js";

export interface FindSimilarChunksParams {
  queryEmbedding: number[];
  provider: string;
  model: string;
  topK: number;
}

export interface SimilarChunkRow {
  chunkId: string;
  content: string;
  chunkIndex: number;
  pageNumber: number | null;
  documentId: string;
  documentName: string;
  similarityScore: number;
}

/**
 * Cosine-distance similarity search over `document_chunk_embeddings`.
 *
 * Only embeddings created by the same `provider` + `model` are compared, so the
 * query vector lives in the same space (and dimensionality) as what was stored
 * during indexing. `similarityScore` is `1 - cosineDistance`: higher is closer.
 */
export async function findSimilarChunks(
  params: FindSimilarChunksParams,
): Promise<SimilarChunkRow[]> {
  const vector = `[${params.queryEmbedding.join(",")}]`;

  return prisma.$queryRawUnsafe<SimilarChunkRow[]>(
    `
      SELECT
        dc.id            AS "chunkId",
        dc.content       AS "content",
        dc.chunk_index   AS "chunkIndex",
        dc.page_number   AS "pageNumber",
        d.id             AS "documentId",
        d.original_name  AS "documentName",
        1 - (dce.embedding <=> $1::vector) AS "similarityScore"
      FROM document_chunk_embeddings dce
      JOIN document_chunks dc ON dc.id = dce."documentChunkId"
      JOIN documents d        ON d.id  = dc."documentId"
      WHERE dce.provider = $2
        AND dce.model    = $3
        AND d.status     = 'INDEXED'
      ORDER BY dce.embedding <=> $1::vector ASC
      LIMIT $4
    `,
    vector,
    params.provider,
    params.model,
    params.topK,
  );
}
