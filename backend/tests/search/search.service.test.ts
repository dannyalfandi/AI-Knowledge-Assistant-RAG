import { beforeEach, describe, expect, it, vi } from "vitest";

import { semanticSearch } from "../../src/modules/search/search.service.js";
import { findSimilarChunks } from "../../src/modules/search/search.repository.js";
import {
  generateEmbedding,
  getEmbeddingProvider,
} from "../../src/services/ai/embedding/embedding.service.js";
import type { SimilarChunkRow } from "../../src/modules/search/search.repository.js";

vi.mock("../../src/modules/search/search.repository.js", () => ({
  findSimilarChunks: vi.fn(),
}));

vi.mock("../../src/services/ai/embedding/embedding.service.js", () => ({
  getEmbeddingProvider: vi.fn(),
  generateEmbedding: vi.fn(),
}));

const findSimilarChunksMock = vi.mocked(findSimilarChunks);
const getEmbeddingProviderMock = vi.mocked(getEmbeddingProvider);
const generateEmbeddingMock = vi.mocked(generateEmbedding);

const QUERY_EMBEDDING = [0.1, 0.2, 0.3];

function buildRow(overrides: Partial<SimilarChunkRow> = {}): SimilarChunkRow {
  return {
    chunkId: "chunk-1",
    content: "Refund dapat diajukan maksimal 7 hari setelah produk diterima.",
    chunkIndex: 3,
    pageNumber: 4,
    documentId: "doc-1",
    documentName: "Refund Policy.pdf",
    similarityScore: 0.87,
    ...overrides,
  };
}

beforeEach(() => {
  vi.clearAllMocks();

  getEmbeddingProviderMock.mockReturnValue({
    provider: "huggingface",
    model: "intfloat/multilingual-e5-small",
    dimensions: 384,
    generateEmbedding: vi.fn(),
  });

  generateEmbeddingMock.mockResolvedValue(QUERY_EMBEDDING);
});

describe("semanticSearch", () => {
  it("embeds the query and maps repository rows into citation results", async () => {
    const rows = [
      buildRow({ chunkId: "chunk-1", similarityScore: 0.91 }),
      buildRow({ chunkId: "chunk-2", similarityScore: 0.72, pageNumber: 12 }),
      buildRow({ chunkId: "chunk-3", similarityScore: 0.55, pageNumber: null }),
    ];
    findSimilarChunksMock.mockResolvedValue(rows);

    const result = await semanticSearch({ query: "batas pengajuan refund?", topK: 5 });

    expect(generateEmbeddingMock).toHaveBeenCalledWith(
      "batas pengajuan refund?",
      "query",
    );
    expect(findSimilarChunksMock).toHaveBeenCalledWith({
      queryEmbedding: QUERY_EMBEDDING,
      provider: "huggingface",
      model: "intfloat/multilingual-e5-small",
      topK: 5,
    });

    expect(result).toEqual({
      query: "batas pengajuan refund?",
      provider: "huggingface",
      model: "intfloat/multilingual-e5-small",
      topK: 5,
      results: [
        {
          chunkId: "chunk-1",
          documentId: "doc-1",
          documentName: "Refund Policy.pdf",
          pageNumber: 4,
          chunkIndex: 3,
          content: rows[0].content,
          similarityScore: 0.91,
        },
        {
          chunkId: "chunk-2",
          documentId: "doc-1",
          documentName: "Refund Policy.pdf",
          pageNumber: 12,
          chunkIndex: 3,
          content: rows[1].content,
          similarityScore: 0.72,
        },
        {
          chunkId: "chunk-3",
          documentId: "doc-1",
          documentName: "Refund Policy.pdf",
          pageNumber: null,
          chunkIndex: 3,
          content: rows[2].content,
          similarityScore: 0.55,
        },
      ],
    });
  });

  it("returns an empty result list when no chunks match", async () => {
    findSimilarChunksMock.mockResolvedValue([]);

    const result = await semanticSearch({ query: "topik tak relevan", topK: 5 });

    expect(result.results).toEqual([]);
  });

  it("forwards the requested topK to the repository unchanged", async () => {
    findSimilarChunksMock.mockResolvedValue([]);

    await semanticSearch({ query: "apa saja", topK: 3 });

    expect(findSimilarChunksMock).toHaveBeenCalledWith(
      expect.objectContaining({ topK: 3 }),
    );
  });

  it("propagates errors from the embedding provider", async () => {
    generateEmbeddingMock.mockRejectedValue(new Error("provider down"));

    await expect(
      semanticSearch({ query: "apa saja", topK: 5 }),
    ).rejects.toThrow("provider down");

    expect(findSimilarChunksMock).not.toHaveBeenCalled();
  });
});
