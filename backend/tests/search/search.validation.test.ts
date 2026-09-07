import { describe, expect, it } from "vitest";

import { searchQuerySchema } from "../../src/modules/search/search.validation.js";

describe("searchQuerySchema", () => {
  it("defaults topK to 5 when omitted", () => {
    const parsed = searchQuerySchema.parse({ query: "refund policy" });

    expect(parsed.topK).toBe(5);
  });

  it("trims the query and rejects an empty one", () => {
    expect(() => searchQuerySchema.parse({ query: "   " })).toThrow();
  });

  it("rejects topK above the allowed maximum", () => {
    expect(() =>
      searchQuerySchema.parse({ query: "refund policy", topK: 50 }),
    ).toThrow();
  });

  it("coerces a numeric string topK", () => {
    const parsed = searchQuerySchema.parse({ query: "refund policy", topK: "3" });

    expect(parsed.topK).toBe(3);
  });
});
