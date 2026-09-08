import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middlewares/auth.middleware.js";

import {
  createDocument,
  deleteDocument,
  getDocumentById,
  listDocuments,
} from "./document.service.js";

import type { DocumentIdInput } from "./document.validation.js";
import { deleteStoredFile } from "../../services/storage/local-storage.service.js";
import { startPdfProcessing } from "./document-processing.service.js";

function documentId(req: AuthenticatedRequest): string {
  return (req.params as unknown as DocumentIdInput).id;
}

export async function listDocumentsController(
  _req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const documents = await listDocuments();

    return res.status(200).json({
      data: documents.map((document) => ({
        ...document,
        fileSize: document.fileSize.toString(),
      })),
    });
  } catch (error) {
    console.error("List documents error:", error);

    return res.status(500).json({
      message: "Internal server error",
    });
  }
}

export async function getDocumentController(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const document = await getDocumentById(documentId(req));

    if (!document) {
      return res.status(404).json({
        message: "Document not found",
      });
    }

    return res.status(200).json({
      data: {
        ...document,
        fileSize: document.fileSize.toString(),
      },
    });
  } catch (error) {
    console.error("Get document error:", error);

    return res.status(500).json({
      message: "Internal server error",
    });
  }
}

export async function uploadDocumentController(
  req: AuthenticatedRequest,
  res: Response,
) {
  if (!req.user) {
    return res.status(401).json({
      message: "Authentication required",
    });
  }

  if (!req.file) {
    return res.status(400).json({
      message: "Document file is required",
    });
  }

  try {
    const document = await createDocument({
      uploadedById: req.user.id,
      originalName: req.file.originalname,
      storedName: req.file.filename,
      filePath: req.file.path,
      mimeType: req.file.mimetype,
      fileSize: req.file.size,
    });

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
  } catch (error) {
    console.error("Upload document error:", error);

    try {
      await deleteStoredFile(req.file.path);
    } catch (cleanupError) {
      console.error("Failed to cleanup uploaded file:", cleanupError);
    }

    return res.status(500).json({
      message: "Internal server error",
    });
  }
}

export async function deleteDocumentController(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const document = await deleteDocument(documentId(req));

    if (!document) {
      return res.status(404).json({
        message: "Document not found",
      });
    }

    return res.status(204).send();
  } catch (error) {
    console.error("Delete document error:", error);

    return res.status(500).json({
      message: "Internal server error",
    });
  }
}

export async function processDocumentController(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const processing = await startPdfProcessing(documentId(req));

    return res.status(202).json({
      data: processing,
    });
  } catch (error) {
    if (error instanceof Error && error.message === "Document not found") {
      return res.status(404).json({
        message: "Document not found",
      });
    }

    if (
      error instanceof Error &&
      error.message === "Document is already being processed"
    ) {
      return res.status(409).json({
        message: error.message,
      });
    }

    console.error("Process document error:", error);

    return res.status(500).json({
      message: "Internal server error",
    });
  }
}
