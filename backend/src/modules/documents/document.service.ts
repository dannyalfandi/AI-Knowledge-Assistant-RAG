import { deleteStoredFile } from "../../services/storage/local-storage.service.js";
import * as documentRepository from "./document.repository.js";

export async function listDocuments() {
  return documentRepository.listDocuments();
}

export async function getDocumentById(id: string) {
  return documentRepository.findDocumentDetailById(id);
}

export async function createDocument(input: {
  uploadedById: string;
  originalName: string;
  storedName: string;
  filePath: string;
  mimeType: string;
  fileSize: number;
}) {
  return documentRepository.createDocument(input);
}

export async function deleteDocument(id: string) {
  const document = await documentRepository.findDocumentPathById(id);

  if (!document) {
    return null;
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
