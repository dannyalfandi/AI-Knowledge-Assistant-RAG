/*
  Warnings:

  - You are about to drop the column `embedding` on the `document_chunks` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "document_chunks" DROP COLUMN "embedding";

-- CreateTable
CREATE TABLE "document_chunk_embeddings" (
    "id" UUID NOT NULL,
    "documentChunkId" UUID NOT NULL,
    "provider" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "dimensions" INTEGER NOT NULL,
    "embedding" vector NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "document_chunk_embeddings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "document_chunk_embeddings_documentChunkId_idx" ON "document_chunk_embeddings"("documentChunkId");

-- CreateIndex
CREATE INDEX "document_chunk_embeddings_provider_model_idx" ON "document_chunk_embeddings"("provider", "model");

-- CreateIndex
CREATE UNIQUE INDEX "document_chunk_embeddings_documentChunkId_provider_model_key" ON "document_chunk_embeddings"("documentChunkId", "provider", "model");

-- AddForeignKey
ALTER TABLE "document_chunk_embeddings" ADD CONSTRAINT "document_chunk_embeddings_documentChunkId_fkey" FOREIGN KEY ("documentChunkId") REFERENCES "document_chunks"("id") ON DELETE CASCADE ON UPDATE CASCADE;
