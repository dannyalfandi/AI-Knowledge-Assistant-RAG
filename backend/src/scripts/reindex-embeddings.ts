import "dotenv/config";

import prisma from "../config/database.js";
import { reprocessDocument } from "../modules/documents/document-processing.service.js";
import { getEmbeddingProvider } from "../services/ai/embedding/embedding.service.js";

/**
 * Re-generates DocumentChunk embeddings using the currently configured embedding
 * provider/model. Old chunks and their embeddings are dropped and rebuilt.
 *
 *   npm run reindex                 # every INDEXED / FAILED document
 *   npm run reindex -- <documentId> # a single document
 *
 * Documents are processed sequentially to stay within the embedding provider's
 * rate limits.
 */
async function main() {
  const targetId = process.argv[2];
  const provider = getEmbeddingProvider();

  const select = {
    id: true,
    originalName: true,
    createdAt: true,
    updatedAt: true,
  } as const;

  const documents = targetId
    ? await prisma.document.findMany({ where: { id: targetId }, select })
    : await prisma.document.findMany({
        where: { status: { in: ["INDEXED", "FAILED"] } },
        orderBy: { createdAt: "asc" },
        select,
      });

  if (documents.length === 0) {
    console.log(
      targetId
        ? `No document found with id ${targetId}`
        : "No INDEXED or FAILED documents to re-index.",
    );
    return;
  }

  console.log(
    `Re-indexing ${documents.length} document(s) with ` +
      `${provider.provider} / ${provider.model} (${provider.dimensions}d)\n`,
  );

  let succeeded = 0;
  let failed = 0;

  for (const [index, document] of documents.entries()) {
    const label = `[${index + 1}/${documents.length}] ${document.originalName}`;

    console.log(
      `${label}\n` +
        `    id=${document.id} created=${document.createdAt.toISOString()} ` +
        `updated=${document.updatedAt.toISOString()} (re-indexed in place, no new row)`,
    );

    try {
      const result = await reprocessDocument(document.id);

      if (result?.status === "INDEXED") {
        succeeded++;
        console.log(`${label} -> INDEXED`);
      } else {
        failed++;
        console.log(
          `${label} -> ${result?.status ?? "UNKNOWN"} (${result?.errorMessage ?? "no error message"})`,
        );
      }
    } catch (error) {
      failed++;
      console.log(
        `${label} -> ERROR (${error instanceof Error ? error.message : "unknown error"})`,
      );
    }
  }

  console.log(`\nDone. ${succeeded} indexed, ${failed} failed.`);

  if (failed > 0) {
    process.exitCode = 1;
  }
}

main()
  .catch((error) => {
    console.error("Re-index script failed:");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => {
    void prisma.$disconnect();
  });
