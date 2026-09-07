import "dotenv/config";

import prisma from "../config/database.js";

/**
 * Read-only diagnostics for the RAG indexing pipeline. Temporary — safe to
 * delete once the embedding issue is resolved.
 *
 *   npm run diagnose:embeddings
 */
async function main() {
  const documents = await prisma.document.findMany({
    orderBy: { createdAt: "asc" },
    select: {
      id: true,
      originalName: true,
      storedName: true,
      status: true,
      errorMessage: true,
      createdAt: true,
      updatedAt: true,
      _count: { select: { chunks: true } },
    },
  });

  console.log(`\n=== Documents (${documents.length}) ===`);
  for (const doc of documents) {
    const embeddingModels = await prisma.documentChunkEmbedding.groupBy({
      by: ["provider", "model"],
      where: { documentChunk: { documentId: doc.id } },
      _count: { _all: true },
    });

    const embeddingSummary =
      embeddingModels.length === 0
        ? "none"
        : embeddingModels
            .map((m) => `${m.model}=${m._count._all}`)
            .join(", ");

    console.log(
      [
        doc.id,
        doc.status.padEnd(10),
        `chunks=${doc._count.chunks}`.padEnd(10),
        `created=${doc.createdAt.toISOString()}`,
        `updated=${doc.updatedAt.toISOString()}`,
        `\n    file: ${doc.originalName}  (stored: ${doc.storedName})`,
        `\n    embeddings: ${embeddingSummary}`,
        doc.errorMessage ? `\n    errorMessage: ${doc.errorMessage}` : "",
      ].join("  "),
    );
  }

  const totalChunks = await prisma.documentChunk.count();
  const totalEmbeddings = await prisma.documentChunkEmbedding.count();

  console.log(`\n=== Totals ===`);
  console.log(`document_chunks:            ${totalChunks}`);
  console.log(`document_chunk_embeddings:  ${totalEmbeddings}`);

  const byModel = await prisma.documentChunkEmbedding.groupBy({
    by: ["provider", "model", "dimensions"],
    _count: { _all: true },
  });

  console.log(`\n=== DocumentChunkEmbedding grouped by provider / model ===`);
  if (byModel.length === 0) {
    console.log("(no embedding rows at all)");
  } else {
    for (const row of byModel) {
      console.log(
        `${row.provider} / ${row.model} (dim=${row.dimensions}): ${row._count._all} rows`,
      );
    }
  }

  const e5Rows = await prisma.documentChunkEmbedding.count({
    where: { model: "intfloat/multilingual-e5-small" },
  });
  console.log(
    `\nRows with model = intfloat/multilingual-e5-small: ${e5Rows}`,
  );
}

main()
  .catch((error) => {
    console.error("Diagnostics failed:");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => {
    void prisma.$disconnect();
  });
