import "dotenv/config";

import prisma from "../config/database.js";
import { deleteDocument } from "../modules/documents/document.service.js";

/**
 * Deletes specific Document rows by id (and, via ON DELETE CASCADE, their
 * DocumentChunk + DocumentChunkEmbedding rows) plus the stored file on disk.
 *
 *   npm run delete:documents -- <id> [<id> ...]            # dry run: only prints
 *   npm run delete:documents -- <id> [<id> ...] --confirm  # actually deletes
 *
 * Temporary maintenance script — safe to delete once the duplicate cleanup is done.
 */
async function main() {
  const args = process.argv.slice(2);
  const confirm = args.includes("--confirm");
  const ids = args.filter((arg) => arg !== "--confirm");

  if (ids.length === 0) {
    console.log(
      "Usage: npm run delete:documents -- <documentId> [<documentId> ...] [--confirm]",
    );
    return;
  }

  console.log(
    confirm
      ? `MODE: DELETE (--confirm set)\n`
      : `MODE: dry run (no --confirm, nothing will be deleted)\n`,
  );

  let deleted = 0;
  let missing = 0;

  for (const id of ids) {
    const document = await prisma.document.findUnique({
      where: { id },
      select: {
        id: true,
        originalName: true,
        storedName: true,
        filePath: true,
        status: true,
        _count: { select: { chunks: true } },
      },
    });

    if (!document) {
      missing++;
      console.log(`- ${id}: NOT FOUND, skipping`);
      continue;
    }

    const embeddingCount = await prisma.documentChunkEmbedding.count({
      where: { documentChunk: { documentId: id } },
    });

    console.log(
      `- ${document.id}\n` +
        `    file:       ${document.originalName} (stored: ${document.storedName})\n` +
        `    status:     ${document.status}\n` +
        `    chunks:     ${document._count.chunks}\n` +
        `    embeddings: ${embeddingCount}\n` +
        `    path:       ${document.filePath}`,
    );

    if (confirm) {
      await deleteDocument(document.id);
      deleted++;
      console.log(`    -> DELETED (document + chunks + embeddings + file)`);
    }
  }

  console.log(
    confirm
      ? `\nDone. ${deleted} deleted, ${missing} not found.`
      : `\nDry run complete. Re-run with --confirm to delete the ${ids.length - missing} document(s) above.`,
  );
}

main()
  .catch((error) => {
    console.error("Delete script failed:");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => {
    void prisma.$disconnect();
  });
