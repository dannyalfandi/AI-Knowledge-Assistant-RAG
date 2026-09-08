import { extractPdfText } from "../../services/document/pdf-extraction.service.js";
import { chunkPages } from "../../services/document/text-chunking.service.js";
import { replaceDocumentChunks } from "../../services/document/document.repository.js";
import { indexDocumentChunks } from "../../services/document/document-indexing.service.js";
import * as documentRepository from "./document.repository.js";

async function runPdfProcessing(documentId: string, filePath: string) {
  try {
    const extraction = await extractPdfText(filePath);

    if (!extraction.text) {
      throw new Error("No text could be extracted from the PDF");
    }

    const chunks = chunkPages(extraction.pages);

    if (chunks.length === 0) {
      throw new Error("No text chunks could be generated from the PDF");
    }

    await replaceDocumentChunks(documentId, chunks);
    await indexDocumentChunks(documentId);

    await documentRepository.updateStatus(documentId, "INDEXED");
  } catch (error) {
    const errorMessage =
      error instanceof Error
        ? error.message
        : "Unknown document processing error";

    console.error(`Document processing failed for ${documentId}:`, error);

    await documentRepository
      .updateStatus(documentId, "FAILED", errorMessage)
      .catch((updateError) => {
        console.error(
          `Failed to mark document ${documentId} as FAILED:`,
          updateError,
        );
      });
  }
}

async function beginProcessing(documentId: string) {
  const document = await documentRepository.findDocumentById(documentId);

  if (!document) {
    throw new Error("Document not found");
  }

  if (document.status === "PROCESSING") {
    throw new Error("Document is already being processed");
  }

  await documentRepository.updateStatus(document.id, "PROCESSING");

  return document;
}

/**
 * Validates the document, moves it to PROCESSING, and kicks off extraction +
 * indexing in the background. Resolves as soon as the work is scheduled so the
 * HTTP request does not block on the (potentially slow) embedding calls.
 *
 * Re-running this on an already-INDEXED document re-indexes it: existing chunks
 * (and their embeddings, via ON DELETE CASCADE) are replaced with freshly
 * generated ones using the currently configured embedding provider/model.
 */
export async function startPdfProcessing(documentId: string) {
  const document = await beginProcessing(documentId);

  void runPdfProcessing(document.id, document.filePath);

  return {
    documentId: document.id,
    status: "PROCESSING" as const,
  };
}

/**
 * Synchronous variant of {@link startPdfProcessing}: awaits the full
 * extract -> chunk -> embed pipeline and returns the resulting document status.
 * Used by the re-index script so documents can be processed one at a time.
 */
export async function reprocessDocument(documentId: string) {
  const document = await beginProcessing(documentId);

  await runPdfProcessing(document.id, document.filePath);

  return documentRepository.findDocumentStatusById(document.id);
}
