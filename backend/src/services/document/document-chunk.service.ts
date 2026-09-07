import prisma from "../../config/database.js";
import type { TextChunk } from "./text-chunking.service.js";

export async function replaceDocumentChunks(
  documentId: string,
  chunks: TextChunk[],
) {
  await prisma.$transaction(async (tx) => {
    await tx.documentChunk.deleteMany({
      where: {
        documentId,
      },
    });

    if (chunks.length === 0) {
      return;
    }

    await tx.documentChunk.createMany({
      data: chunks.map((chunk) => ({
        documentId,
        content: chunk.content,
        chunkIndex: chunk.chunkIndex,
        pageNumber: chunk.pageNumber,
        tokenCount: chunk.tokenCount,
      })),
    });
  });
}

export async function getDocumentChunks(documentId: string) {
  return prisma.documentChunk.findMany({
    where: {
      documentId,
    },
    orderBy: {
      chunkIndex: "asc",
    },
  });
}
