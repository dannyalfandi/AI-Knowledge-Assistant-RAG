import type { Response } from "express";

import {
  requireUserId,
  type AuthenticatedRequest,
} from "../../middlewares/auth.middleware.js";
import * as documentProcessingService from "./document-processing.service.js";
import * as documentService from "./document.service.js";
import type { DocumentIdInput } from "./document.validation.js";

function documentId(req: AuthenticatedRequest): string {
  return (req.params as unknown as DocumentIdInput).id;
}

export async function listDocumentsController(
  _req: AuthenticatedRequest,
  res: Response,
) {
  const documents = await documentService.listDocuments();

  return res.status(200).json({
    data: documents.map((document) => ({
      ...document,
      fileSize: document.fileSize.toString(),
    })),
  });
}

export async function getDocumentController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const document = await documentService.getDocumentById(documentId(req));

  return res.status(200).json({
    data: {
      ...document,
      fileSize: document.fileSize.toString(),
    },
  });
}

export async function uploadDocumentController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const document = await documentService.createDocumentFromUpload(
    requireUserId(req),
    req.file,
  );

  return res.status(201).json({
    data: {
      id: document.id,
      originalName: document.originalName,
      mimeType: document.mimeType,
      fileSize: document.fileSize.toString(),
      status: document.status,
      createdAt: document.createdAt,
    },
  });
}

export async function deleteDocumentController(
  req: AuthenticatedRequest,
  res: Response,
) {
  await documentService.deleteDocument(documentId(req));

  return res.status(204).send();
}

export async function processDocumentController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const processing = await documentProcessingService.startPdfProcessing(
    documentId(req),
  );

  return res.status(202).json({ data: processing });
}
