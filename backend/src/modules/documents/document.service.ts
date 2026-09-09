import { deleteStoredFile } from "../../services/storage/local-storage.service.js";
import { BadRequestError, NotFoundError } from "../../utils/errors.js";
import * as documentRepository from "./document.repository.js";

/** The fields the upload flow consumes from a stored Multer file. */
export interface UploadedFile {
  originalname: string;
  filename: string;
  path: string;
  mimetype: string;
  size: number;
}

export async function listDocuments() {
  return documentRepository.listDocuments();
}

export async function getDocumentById(id: string) {
  const document = await documentRepository.findDocumentDetailById(id);

  if (!document) {
    throw new NotFoundError("Document not found");
  }

  return document;
}

export async function createDocumentFromUpload(
  uploadedById: string,
  file: UploadedFile | undefined,
) {
  if (!file) {
    throw new BadRequestError("Document file is required");
  }

  try {
    return await documentRepository.createDocument({
      uploadedById,
      originalName: file.originalname,
      storedName: file.filename,
      filePath: file.path,
      mimeType: file.mimetype,
      fileSize: file.size,
    });
  } catch (error) {
    // Multer has already written the file to disk; if persisting the row
    // fails, remove the orphaned file before rethrowing so storage doesn't leak.
    await deleteStoredFile(file.path).catch((cleanupError) => {
      console.error(
        `Failed to clean up orphaned upload ${file.path}:`,
        cleanupError,
      );
    });

    throw error;
  }
}

export async function deleteDocument(id: string) {
  const document = await documentRepository.findDocumentPathById(id);

  if (!document) {
    throw new NotFoundError("Document not found");
  }

  await documentRepository.deleteDocumentById(id);

  try {
    await deleteStoredFile(document.filePath);
  } catch (error) {
    console.error(
      `Failed to delete stored file for document ${document.id}:`,
      error,
    );
  }

  return document;
}
