import { readFile } from "node:fs/promises";
import { PDFParse } from "pdf-parse";

export interface PdfPageText {
  pageNumber: number;
  text: string;
}

export interface PdfExtractionResult {
  text: string;
  totalPages: number;
  pages: PdfPageText[];
}

export async function extractPdfText(
  filePath: string,
): Promise<PdfExtractionResult> {
  const fileBuffer = await readFile(filePath);

  const parser = new PDFParse({
    data: fileBuffer,
  });

  try {
    const result = await parser.getText();

    const pages: PdfPageText[] = [];

    for (let pageNumber = 1; pageNumber <= result.total; pageNumber++) {
      const pageText = result.getPageText(pageNumber).trim();

      if (!pageText) {
        continue;
      }

      pages.push({
        pageNumber,
        text: pageText,
      });
    }

    return {
      text: result.text.trim(),
      totalPages: result.total,
      pages,
    };
  } finally {
    await parser.destroy();
  }
}
