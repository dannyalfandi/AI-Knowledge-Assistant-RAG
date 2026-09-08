import { describe, expect, it } from "vitest";

import {
  applyInputPrefix,
  getInputPrefix,
} from "../../src/services/ai/embedding/embedding-model-config.js";

const E5 = "intfloat/multilingual-e5-small";
const MINILM = "sentence-transformers/all-MiniLM-L6-v2";

describe("getInputPrefix", () => {
  it("returns the E5 prefixes for a registered E5 model", () => {
    expect(getInputPrefix(E5, "query")).toBe("query: ");
    expect(getInputPrefix(E5, "passage")).toBe("passage: ");
  });

  it("returns no prefix for a model that is not registered", () => {
    expect(getInputPrefix(MINILM, "query")).toBe("");
    expect(getInputPrefix(MINILM, "passage")).toBe("");
    expect(getInputPrefix("text-embedding-3-small", "query")).toBe("");
  });

  it("returns no prefix when the input type is undefined", () => {
    expect(getInputPrefix(E5, undefined)).toBe("");
  });
});

describe("applyInputPrefix", () => {
  it("prepends the prefix for an E5 model", () => {
    expect(applyInputPrefix(E5, "berapa lama refund?", "query")).toBe(
      "query: berapa lama refund?",
    );
    expect(applyInputPrefix(E5, "Refund dalam 7 hari.", "passage")).toBe(
      "passage: Refund dalam 7 hari.",
    );
  });

  it("leaves the text untouched for a non-E5 model", () => {
    expect(applyInputPrefix(MINILM, "hello world", "passage")).toBe(
      "hello world",
    );
  });

  it("leaves the text untouched when no input type is given", () => {
    expect(applyInputPrefix(E5, "hello world", undefined)).toBe("hello world");
  });
});
