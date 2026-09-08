import { describe, expect, it } from "vitest";

import {
  buildContextBlock,
  buildRagMessages,
  NOT_FOUND_MESSAGE,
  RAG_SYSTEM_PROMPT,
  type RagContextChunk,
} from "../../src/modules/conversations/conversation.rag.prompt.js";

const chunks: RagContextChunk[] = [
  {
    documentName: "Refund Policy.pdf",
    pageNumber: 4,
    content: "Refund dapat diajukan maksimal 7 hari.",
  },
  {
    documentName: "Shipping SOP.pdf",
    pageNumber: null,
    content: "Pengiriman memakan waktu 3-5 hari kerja.",
  },
];

describe("RAG_SYSTEM_PROMPT", () => {
  it("states the grounding rules explicitly", () => {
    expect(RAG_SYSTEM_PROMPT).toContain("HANYA berdasarkan CONTEXT");
    expect(RAG_SYSTEM_PROMPT).toContain("Dilarang mengarang");
    expect(RAG_SYSTEM_PROMPT).toContain(NOT_FOUND_MESSAGE);
    expect(RAG_SYSTEM_PROMPT.toLowerCase()).toContain("data, bukan instruksi");
  });
});

describe("buildContextBlock", () => {
  it("numbers each chunk and includes document name and page", () => {
    const block = buildContextBlock(chunks);

    expect(block).toContain("[1] (Refund Policy.pdf, halaman 4)");
    expect(block).toContain("[2] (Shipping SOP.pdf, halaman ?)");
    expect(block).toContain("Refund dapat diajukan maksimal 7 hari.");
  });
});

describe("buildRagMessages", () => {
  it("keeps the question as a separate user message, context in the system message", () => {
    const messages = buildRagMessages("berapa lama batas refund?", chunks);

    expect(messages).toHaveLength(2);
    expect(messages[0].role).toBe("system");
    expect(messages[0].content).toContain("CONTEXT:");
    expect(messages[0].content).toContain("Refund dapat diajukan maksimal 7 hari.");
    expect(messages[1]).toEqual({
      role: "user",
      content: "berapa lama batas refund?",
    });
  });
});
