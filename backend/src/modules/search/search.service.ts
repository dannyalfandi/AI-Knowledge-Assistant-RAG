import {
  generateEmbedding,
  getEmbeddingProvider,
} from "../../services/ai/embedding/embedding.service.js";
import { findSimilarChunks } from "./search.repository.js";
import type { SearchQueryInput } from "./search.validation.js";

export interface SearchResultItem {
  chunkId: string;
  documentId: string;
  documentName: string;
  pageNumber: number | null;
  chunkIndex: number;
  content: string;
  similarityScore: number;
}

export interface SemanticSearchResult {
  query: string;
  provider: string;
  model: string;
  topK: number;
  results: SearchResultItem[];
}

export async function semanticSearch(
  input: SearchQueryInput,
): Promise<SemanticSearchResult> {
  const provider = getEmbeddingProvider();
  const queryEmbedding = await generateEmbedding(input.query, "query");

  const rows = await findSimilarChunks({
    queryEmbedding,
    provider: provider.provider,
    model: provider.model,
    topK: input.topK,
  });

  return {
    query: input.query,
    provider: provider.provider,
    model: provider.model,
    topK: input.topK,
    results: rows.map((row) => ({
      chunkId: row.chunkId,
      documentId: row.documentId,
      documentName: row.documentName,
      pageNumber: row.pageNumber,
      chunkIndex: row.chunkIndex,
      content: row.content,
      similarityScore: row.similarityScore,
    })),
  };
}
