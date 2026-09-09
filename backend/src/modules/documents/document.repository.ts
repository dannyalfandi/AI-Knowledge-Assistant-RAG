import prisma from "../../config/database.js";

type DocumentStatus = "PENDING" | "PROCESSING" | "INDEXED" | "FAILED";

const documentDetailSelect = {
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
} as const;

export async function listDocuments() {
  return prisma.document.findMany({
    orderBy: {
      createdAt: "desc",
    },
    select: documentDetailSelect,
  });
}

export async function findDocumentDetailById(id: string) {
  return prisma.document.findUnique({
    where: { id },
    select: documentDetailSelect,
  });
}

export async function findDocumentById(id: string) {
  return prisma.document.findUnique({
    where: { id },
  });
}

export async function findDocumentStatusById(id: string) {
  return prisma.document.findUnique({
    where: { id },
    select: {
      id: true,
      status: true,
      errorMessage: true,
    },
  });
}

export async function findDocumentPathById(id: string) {
  return prisma.document.findUnique({
    where: { id },
    select: {
      id: true,
      filePath: true,
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

export async function updateStatus(
  id: string,
  status: DocumentStatus,
  errorMessage?: string,
) {
  return prisma.document.update({
    where: { id },
    data: {
      status,
      errorMessage:
        status === "FAILED"
          ? (errorMessage ?? "Document processing failed")
          : null,
    },
  });
}

export async function deleteDocumentById(id: string) {
  return prisma.document.delete({
    where: { id },
  });
}
