export interface TextChunkInput {
  pageNumber: number;
  text: string;
}

export interface TextChunk {
  content: string;
  chunkIndex: number;
  pageNumber: number;
  tokenCount: number;
}

const CHUNK_SIZE = 1500;
const CHUNK_OVERLAP = 200;

function estimateTokenCount(text: string): number {
  return Math.ceil(text.length / 4);
}

function splitText(text: string, chunkSize: number, overlap: number): string[] {
  const normalizedText = text.replace(/\s+/g, " ").trim();

  if (!normalizedText) {
    return [];
  }

  if (normalizedText.length <= chunkSize) {
    return [normalizedText];
  }

  const chunks: string[] = [];

  let start = 0;

  while (start < normalizedText.length) {
    const end = Math.min(start + chunkSize, normalizedText.length);

    let chunk = normalizedText.slice(start, end);

    if (end < normalizedText.length) {
      const lastSpace = chunk.lastIndexOf(" ");

      if (lastSpace > chunkSize * 0.7) {
        chunk = chunk.slice(0, lastSpace);
      }
    }

    chunk = chunk.trim();

    if (chunk) {
      chunks.push(chunk);
    }

    if (end >= normalizedText.length) {
      break;
    }

    const nextStart = start + Math.max(chunk.length - overlap, 1);

    start = nextStart;
  }

  return chunks;
}

export function chunkPages(pages: TextChunkInput[]): TextChunk[] {
  const chunks: TextChunk[] = [];

  let chunkIndex = 0;

  for (const page of pages) {
    const pageChunks = splitText(page.text, CHUNK_SIZE, CHUNK_OVERLAP);

    for (const content of pageChunks) {
      chunks.push({
        content,
        chunkIndex,
        pageNumber: page.pageNumber,
        tokenCount: estimateTokenCount(content),
      });

      chunkIndex++;
    }
  }

  return chunks;
}
