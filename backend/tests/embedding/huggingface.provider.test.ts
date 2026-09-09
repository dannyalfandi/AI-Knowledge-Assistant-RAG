import { describe, expect, it, vi } from "vitest";

vi.mock("@huggingface/inference", () => ({
  InferenceClient: class {},
}));

vi.mock("../../src/config/env.js", () => ({
  env: {
    EMBEDDING_MODEL: "intfloat/multilingual-e5-small",
    EMBEDDING_DIMENSIONS: 384,
    HF_TOKEN: "test-token",
  },
}));

const { toVector } = await import(
  "../../src/services/ai/embedding/huggingface.provider.js"
);

describe("toVector", () => {
  it("returns an already-pooled number[] unchanged", () => {
    const pooled = [0.1, -0.2, 0.3];

    expect(toVector(pooled)).toEqual(pooled);
  });

  it("mean-pools a token-level number[][] across the token axis", () => {
    const tokenLevel = [
      [1, 2, 3],
      [3, 4, 5],
      [5, 6, 7],
    ];

    expect(toVector(tokenLevel)).toEqual([3, 4, 5]);
  });

  it("keeps the row length as the output dimension when pooling", () => {
    const result = toVector([
      [0, 10],
      [2, 20],
    ]);

    expect(result).toEqual([1, 15]);
    expect(result).toHaveLength(2);
  });

  it("throws a clear error for an empty array", () => {
    expect(() => toVector([])).toThrow(
      "Unexpected embedding response from Hugging Face",
    );
  });

  it("throws a clear error for a non-array response", () => {
    expect(() => toVector("nope")).toThrow(
      "Unexpected embedding response from Hugging Face",
    );
    expect(() => toVector(null)).toThrow(
      "Unexpected embedding response from Hugging Face",
    );
  });

  it("throws when a token row contains a non-number", () => {
    expect(() =>
      toVector([
        [1, 2],
        ["x", 3],
      ]),
    ).toThrow("Unexpected embedding response from Hugging Face");
  });
});
