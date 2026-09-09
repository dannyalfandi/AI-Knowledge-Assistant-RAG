import { beforeEach, describe, expect, it, vi } from "vitest";

import * as documentProcessingService from "../../src/modules/documents/document-processing.service.js";
import * as documentRepository from "../../src/modules/documents/document.repository.js";
import { replaceDocumentChunks } from "../../src/services/document/document.repository.js";
import { extractPdfText } from "../../src/services/document/pdf-extraction.service.js";
import { chunkPages } from "../../src/services/document/text-chunking.service.js";
import { indexDocumentChunks } from "../../src/services/document/document-indexing.service.js";
import { ConflictError, NotFoundError } from "../../src/utils/errors.js";

vi.mock("../../src/modules/documents/document.repository.js", () => ({
  findDocumentById: vi.fn(),
  findDocumentStatusById: vi.fn(),
  updateStatus: vi.fn(),
}));

vi.mock("../../src/services/document/document.repository.js", () => ({
  replaceDocumentChunks: vi.fn(),
}));

vi.mock("../../src/services/document/pdf-extraction.service.js", () => ({
  extractPdfText: vi.fn(),
}));

vi.mock("../../src/services/document/text-chunking.service.js", () => ({
  chunkPages: vi.fn(),
}));

vi.mock("../../src/services/document/document-indexing.service.js", () => ({
  indexDocumentChunks: vi.fn(),
}));

const repo = vi.mocked(documentRepository);
const replaceDocumentChunksMock = vi.mocked(replaceDocumentChunks);
const extractPdfTextMock = vi.mocked(extractPdfText);
const chunkPagesMock = vi.mocked(chunkPages);
const indexDocumentChunksMock = vi.mocked(indexDocumentChunks);

const DOC_ID = "11111111-1111-1111-1111-111111111111";
const FILE_PATH = "/storage/documents/abc.pdf";

const pages = [{ pageNumber: 1, text: "hello world" }];
const chunks = [
  { content: "hello world", chunkIndex: 0, pageNumber: 1, tokenCount: 3 },
];

/** Lets the fire-and-forget runPdfProcessing kicked off by startPdfProcessing settle. */
function flush() {
  return new Promise((resolve) => setImmediate(resolve));
}

function stubDocument(status: string) {
  return { id: DOC_ID, filePath: FILE_PATH, status } as never;
}

beforeEach(() => {
  vi.clearAllMocks();
  repo.updateStatus.mockResolvedValue({} as never);
  repo.findDocumentStatusById.mockResolvedValue({
    id: DOC_ID,
    status: "INDEXED",
    errorMessage: null,
  } as never);
  extractPdfTextMock.mockResolvedValue({
    text: "hello world",
    totalPages: 1,
    pages,
  } as never);
  chunkPagesMock.mockReturnValue(chunks as never);
  replaceDocumentChunksMock.mockResolvedValue(undefined as never);
  indexDocumentChunksMock.mockResolvedValue({
    documentId: DOC_ID,
    indexedCount: 1,
  } as never);
});

describe("beginProcessing (via startPdfProcessing)", () => {
  it("throws NotFoundError and touches nothing when the document does not exist", async () => {
    repo.findDocumentById.mockResolvedValue(null);

    await expect(
      documentProcessingService.startPdfProcessing(DOC_ID),
    ).rejects.toBeInstanceOf(NotFoundError);

    expect(repo.updateStatus).not.toHaveBeenCalled();
    expect(extractPdfTextMock).not.toHaveBeenCalled();
  });

  it("throws ConflictError without side effects when the document is already PROCESSING", async () => {
    repo.findDocumentById.mockResolvedValue(stubDocument("PROCESSING"));

    await expect(
      documentProcessingService.startPdfProcessing(DOC_ID),
    ).rejects.toBeInstanceOf(ConflictError);

    expect(repo.updateStatus).not.toHaveBeenCalled();
    expect(extractPdfTextMock).not.toHaveBeenCalled();
  });

  it("moves a PENDING document to PROCESSING and returns the scheduling result", async () => {
    repo.findDocumentById.mockResolvedValue(stubDocument("PENDING"));

    const result = await documentProcessingService.startPdfProcessing(DOC_ID);

    expect(result).toEqual({ documentId: DOC_ID, status: "PROCESSING" });
    expect(repo.updateStatus).toHaveBeenCalledWith(DOC_ID, "PROCESSING");

    await flush();
  });

  it("also allows re-processing a FAILED document", async () => {
    repo.findDocumentById.mockResolvedValue(stubDocument("FAILED"));

    await documentProcessingService.startPdfProcessing(DOC_ID);

    expect(repo.updateStatus).toHaveBeenCalledWith(DOC_ID, "PROCESSING");

    await flush();
  });
});

describe("runPdfProcessing (via reprocessDocument)", () => {
  it("indexes the chunks and marks the document INDEXED with no error message", async () => {
    repo.findDocumentById.mockResolvedValue(stubDocument("INDEXED"));

    await documentProcessingService.reprocessDocument(DOC_ID);

    expect(replaceDocumentChunksMock).toHaveBeenCalledWith(DOC_ID, chunks);
    expect(indexDocumentChunksMock).toHaveBeenCalledWith(DOC_ID);

    const indexedCall = repo.updateStatus.mock.calls.find(
      (call) => call[1] === "INDEXED",
    );
    expect(indexedCall).toEqual([DOC_ID, "INDEXED"]);
    expect(
      repo.updateStatus.mock.calls.some((call) => call[1] === "FAILED"),
    ).toBe(false);
  });

  it("marks the document FAILED with the original exception message", async () => {
    repo.findDocumentById.mockResolvedValue(stubDocument("INDEXED"));
    indexDocumentChunksMock.mockRejectedValue(
      new Error("embedding provider exploded"),
    );

    await expect(
      documentProcessingService.reprocessDocument(DOC_ID),
    ).resolves.not.toThrow();

    expect(repo.updateStatus).toHaveBeenCalledWith(
      DOC_ID,
      "FAILED",
      "embedding provider exploded",
    );
  });

  it("marks the document FAILED when the PDF yields no text", async () => {
    repo.findDocumentById.mockResolvedValue(stubDocument("PENDING"));
    extractPdfTextMock.mockResolvedValue({
      text: "",
      totalPages: 0,
      pages: [],
    } as never);

    await documentProcessingService.reprocessDocument(DOC_ID);

    expect(repo.updateStatus).toHaveBeenCalledWith(
      DOC_ID,
      "FAILED",
      "No text could be extracted from the PDF",
    );
    expect(replaceDocumentChunksMock).not.toHaveBeenCalled();
  });

  it("returns the freshly read document status", async () => {
    repo.findDocumentById.mockResolvedValue(stubDocument("FAILED"));
    repo.findDocumentStatusById.mockResolvedValue({
      id: DOC_ID,
      status: "INDEXED",
      errorMessage: null,
    } as never);

    const result = await documentProcessingService.reprocessDocument(DOC_ID);

    expect(repo.findDocumentStatusById).toHaveBeenCalledWith(DOC_ID);
    expect(result).toEqual({
      id: DOC_ID,
      status: "INDEXED",
      errorMessage: null,
    });
  });
});
