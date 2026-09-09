import { describe, expect, it } from "vitest";

import {
  chunkPages,
  type TextChunkInput,
} from "../../src/services/document/text-chunking.service.js";

const CHUNK_SIZE = 1500;
const CHUNK_OVERLAP = 200;

function page(pageNumber: number, text: string): TextChunkInput {
  return { pageNumber, text };
}

describe("chunkPages", () => {
  it("keeps a short page as a single chunk indexed from zero", () => {
    const result = chunkPages([page(1, "Refund dapat diajukan maksimal 7 hari.")]);

    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      content: "Refund dapat diajukan maksimal 7 hari.",
      chunkIndex: 0,
      pageNumber: 1,
    });
    expect(result[0].tokenCount).toBe(
      Math.ceil("Refund dapat diajukan maksimal 7 hari.".length / 4),
    );
  });

  it("normalizes runs of whitespace to a single space", () => {
    const result = chunkPages([page(1, "hello   \n\n  world\t\ttab   end")]);

    expect(result).toHaveLength(1);
    expect(result[0].content).toBe("hello world tab end");
  });

  it("splits a long page into overlapping chunks", () => {
    const text = new Array(400).fill("word").join(" "); // ~1999 chars
    expect(text.length).toBeGreaterThan(CHUNK_SIZE);

    const result = chunkPages([page(1, text)]);

    expect(result.length).toBeGreaterThanOrEqual(2);
    expect(result.map((chunk) => chunk.chunkIndex)).toEqual(
      result.map((_, index) => index),
    );

    // The second chunk restarts ~CHUNK_OVERLAP chars before the first chunk's
    // slice ended, so its opening text is also present near the end of chunk 1.
    const secondChunkOpening = result[1].content.slice(0, 80);
    expect(result[0].content).toContain(secondChunkOpening);

    // Rough overlap-size sanity: the restart offset is chunkLen - overlap.
    const firstChunkLen = result[0].content.length;
    expect(firstChunkLen).toBeGreaterThan(CHUNK_SIZE - CHUNK_OVERLAP * 2);
  });

  it("continues chunkIndex across pages instead of resetting per page", () => {
    const longText = new Array(400).fill("word").join(" ");

    const result = chunkPages([page(1, longText), page(2, "halaman dua singkat")]);

    expect(result.length).toBeGreaterThanOrEqual(3);

    const pageOneChunks = result.filter((chunk) => chunk.pageNumber === 1);
    const pageTwoChunks = result.filter((chunk) => chunk.pageNumber === 2);

    expect(pageOneChunks.length).toBeGreaterThanOrEqual(2);
    expect(pageTwoChunks).toHaveLength(1);

    // page 2's chunk index picks up right after page 1's last chunk
    expect(pageTwoChunks[0].chunkIndex).toBe(pageOneChunks.length);
    expect(result.map((chunk) => chunk.chunkIndex)).toEqual([
      ...result.keys(),
    ]);
  });

  it("cuts at the nearest space so words are never split mid-token", () => {
    const word = "abcdefg";
    const text = new Array(300).fill(word).join(" "); // ~2399 chars
    expect(text.length).toBeGreaterThan(CHUNK_SIZE);

    const result = chunkPages([page(1, text)]);

    expect(result.length).toBeGreaterThanOrEqual(2);

    for (const chunk of result) {
      const tokens = chunk.content.split(" ");
      expect(tokens.every((token) => token === word)).toBe(true);
    }

    // first chunk was truncated at a space -> shorter than CHUNK_SIZE but still
    // past the 70% floor the splitter enforces
    expect(result[0].content.length).toBeLessThan(CHUNK_SIZE);
    expect(result[0].content.length).toBeGreaterThan(CHUNK_SIZE * 0.7);
  });

  it("drops pages that are empty or whitespace-only", () => {
    const result = chunkPages([
      page(1, "   \n\t  "),
      page(2, "isi halaman dua"),
    ]);

    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      content: "isi halaman dua",
      chunkIndex: 0,
      pageNumber: 2,
    });
  });
});
