import { describe, expect, it } from "vitest";

import {
  AUTO_TITLE_MAX_LENGTH,
  buildAutoTitle,
} from "../../src/modules/conversations/conversation.title.js";

describe("buildAutoTitle", () => {
  it("uses a short question verbatim, with no ellipsis", () => {
    expect(buildAutoTitle("Berapa lama proses refund?")).toBe(
      "Berapa lama proses refund?",
    );
  });

  it("collapses whitespace so a multi-line question stays one line", () => {
    expect(buildAutoTitle("  Berapa lama\n\n  proses   refund? ")).toBe(
      "Berapa lama proses refund?",
    );
  });

  it("cuts at a word boundary and never mid-word", () => {
    const question =
      "Bagaimana prosedur pengajuan refund untuk produk elektronik yang rusak?";

    const title = buildAutoTitle(question)!;

    expect(title.endsWith("...")).toBe(true);
    expect(title.length).toBeLessThanOrEqual(AUTO_TITLE_MAX_LENGTH + 3);

    // Every word kept must be a whole word from the original question.
    const words = title.slice(0, -3).split(" ");
    for (const word of words) {
      expect(question.split(/\s+/)).toContain(word);
    }
  });

  it("drops punctuation left dangling at the cut", () => {
    const title = buildAutoTitle(
      "Berapa lama proses pengajuan refund elektronik, dan apa syaratnya?",
    )!;

    expect(title).not.toContain(",...");
    expect(title.endsWith("...")).toBe(true);
  });

  it("hard-cuts a single word longer than the limit", () => {
    const question = "a".repeat(80);

    const title = buildAutoTitle(question)!;

    expect(title).toBe(`${"a".repeat(AUTO_TITLE_MAX_LENGTH)}...`);
  });

  it("does not add an ellipsis to text that exactly fits", () => {
    const question = "a".repeat(AUTO_TITLE_MAX_LENGTH);

    expect(buildAutoTitle(question)).toBe(question);
  });

  it("returns null for a question with no usable text", () => {
    expect(buildAutoTitle("   ")).toBeNull();
    expect(buildAutoTitle("")).toBeNull();
  });
});
