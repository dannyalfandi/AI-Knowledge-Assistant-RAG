import { beforeEach, describe, expect, it, vi } from "vitest";

import * as documentService from "../../src/modules/documents/document.service.js";
import * as documentRepository from "../../src/modules/documents/document.repository.js";
import { deleteStoredFile } from "../../src/services/storage/local-storage.service.js";
import { BadRequestError, NotFoundError } from "../../src/utils/errors.js";

vi.mock("../../src/modules/documents/document.repository.js", () => ({
  listDocuments: vi.fn(),
  findDocumentDetailById: vi.fn(),
  createDocument: vi.fn(),
  findDocumentPathById: vi.fn(),
  deleteDocumentById: vi.fn(),
}));

vi.mock("../../src/services/storage/local-storage.service.js", () => ({
  deleteStoredFile: vi.fn(),
}));

const repo = vi.mocked(documentRepository);
const deleteStoredFileMock = vi.mocked(deleteStoredFile);

const DOC_ID = "11111111-1111-1111-1111-111111111111";

const uploadedFile = {
  originalname: "refund-policy.pdf",
  filename: "stored-uuid.pdf",
  path: "/storage/documents/stored-uuid.pdf",
  mimetype: "application/pdf",
  size: 20480,
};

beforeEach(() => {
  vi.clearAllMocks();
  vi.spyOn(console, "error").mockImplementation(() => {});
  deleteStoredFileMock.mockResolvedValue(undefined as never);
});

describe("getDocumentById", () => {
  it("throws NotFoundError when the repository has no such document", async () => {
    repo.findDocumentDetailById.mockResolvedValue(null);

    await expect(documentService.getDocumentById(DOC_ID)).rejects.toBeInstanceOf(
      NotFoundError,
    );
  });

  it("returns the document when it exists", async () => {
    const document = { id: DOC_ID, originalName: "x.pdf" };
    repo.findDocumentDetailById.mockResolvedValue(document as never);

    await expect(documentService.getDocumentById(DOC_ID)).resolves.toBe(
      document,
    );
  });
});

describe("deleteDocument", () => {
  it("throws NotFoundError and deletes nothing when the document is missing", async () => {
    repo.findDocumentPathById.mockResolvedValue(null);

    await expect(documentService.deleteDocument(DOC_ID)).rejects.toBeInstanceOf(
      NotFoundError,
    );

    expect(repo.deleteDocumentById).not.toHaveBeenCalled();
    expect(deleteStoredFileMock).not.toHaveBeenCalled();
  });

  it("removes the row and the stored file", async () => {
    repo.findDocumentPathById.mockResolvedValue({
      id: DOC_ID,
      filePath: "/storage/documents/stored-uuid.pdf",
    } as never);

    await documentService.deleteDocument(DOC_ID);

    expect(repo.deleteDocumentById).toHaveBeenCalledWith(DOC_ID);
    expect(deleteStoredFileMock).toHaveBeenCalledWith(
      "/storage/documents/stored-uuid.pdf",
    );
  });

  it("still resolves when the stored file cannot be removed (best effort)", async () => {
    repo.findDocumentPathById.mockResolvedValue({
      id: DOC_ID,
      filePath: "/storage/documents/stored-uuid.pdf",
    } as never);
    deleteStoredFileMock.mockRejectedValue(new Error("ENOENT"));

    await expect(
      documentService.deleteDocument(DOC_ID),
    ).resolves.not.toThrow();

    expect(repo.deleteDocumentById).toHaveBeenCalledWith(DOC_ID);
  });
});

describe("createDocumentFromUpload", () => {
  it("throws BadRequestError when no file was uploaded", async () => {
    await expect(
      documentService.createDocumentFromUpload("user-1", undefined),
    ).rejects.toBeInstanceOf(BadRequestError);

    expect(repo.createDocument).not.toHaveBeenCalled();
  });

  it("maps the stored file onto a new document row", async () => {
    const created = { id: DOC_ID };
    repo.createDocument.mockResolvedValue(created as never);

    const result = await documentService.createDocumentFromUpload(
      "user-1",
      uploadedFile,
    );

    expect(repo.createDocument).toHaveBeenCalledWith({
      uploadedById: "user-1",
      originalName: "refund-policy.pdf",
      storedName: "stored-uuid.pdf",
      filePath: "/storage/documents/stored-uuid.pdf",
      mimeType: "application/pdf",
      fileSize: 20480,
    });
    expect(result).toBe(created);
    expect(deleteStoredFileMock).not.toHaveBeenCalled();
  });

  it("cleans up the orphaned file and rethrows when the insert fails", async () => {
    const insertError = new Error("unique constraint");
    repo.createDocument.mockRejectedValue(insertError);

    await expect(
      documentService.createDocumentFromUpload("user-1", uploadedFile),
    ).rejects.toBe(insertError);

    expect(deleteStoredFileMock).toHaveBeenCalledWith(
      "/storage/documents/stored-uuid.pdf",
    );
  });
});
