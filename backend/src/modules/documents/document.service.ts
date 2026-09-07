import prisma from "../../config/database.js";
import { deleteStoredFile } from "../../services/storage/local-storage.service.js";

export async function listDocuments() {
  return prisma.document.findMany({
    orderBy: {
      createdAt: "desc",
    },
    select: {
      id: true,
      originalName: true,
      mimeType: true,
      fileSize: true,
      status: true,
      errorMessage: true,
      createdAt: true,
      updatedAt: true,
      uploadedBy: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      _count: {
        select: {
          chunks: true,
        },
      },
    },
  });
}

export async function getDocumentById(id: string) {
  return prisma.document.findUnique({
    where: {
      id,
    },
    select: {
      id: true,
      originalName: true,
      mimeType: true,
      fileSize: true,
      status: true,
      errorMessage: true,
      createdAt: true,
      updatedAt: true,
      uploadedBy: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      _count: {
        select: {
          chunks: true,
        },
      },
    },
  });
}

export async function createDocument(input: {
  uploadedById: string;
  originalName: string;
  storedName: string;
  filePath: string;
  mimeType: string;
  fileSize: number;
}) {
  return prisma.document.create({
    data: {
      uploadedById: input.uploadedById,
      originalName: input.originalName,
      storedName: input.storedName,
      filePath: input.filePath,
      mimeType: input.mimeType,
      fileSize: BigInt(input.fileSize),
      status: "PENDING",
    },
  });
}

export async function updateDocumentStatus(
  id: string,
  status: "PENDING" | "PROCESSING" | "INDEXED" | "FAILED",
  errorMessage?: string,
) {
  return prisma.document.update({
    where: {
      id,
    },
    data: {
      status,
      errorMessage:
        status === "FAILED"
          ? (errorMessage ?? "Document processing failed")
          : null,
    },
  });
}

export async function deleteDocument(id: string) {
  const document = await prisma.document.findUnique({
    where: {
      id,
    },
    select: {
      id: true,
      filePath: true,
    },
  });

  if (!document) {
    return null;
  }

  await prisma.document.delete({
    where: {
      id,
    },
  });

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
