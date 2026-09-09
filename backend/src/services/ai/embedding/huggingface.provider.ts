import { InferenceClient } from "@huggingface/inference";

import { env } from "../../../config/env.js";
import { applyInputPrefix } from "./embedding-model-config.js";
import type {
  EmbeddingInputType,
  EmbeddingProvider,
} from "./embedding-provider.js";

export function toVector(result: unknown): number[] {
  // featureExtraction returns (number | number[] | number[][])[].
  // For a single string input this is normally number[] (already pooled).
  if (!Array.isArray(result) || result.length === 0) {
    throw new Error("Unexpected embedding response from Hugging Face");
  }

  if (typeof result[0] === "number") {
    return result as number[];
  }

  // Token-level output: mean-pool across the token axis.
  const rows = result as unknown[];
  const matrix = rows.map((row) => {
    if (!Array.isArray(row) || row.some((value) => typeof value !== "number")) {
      throw new Error("Unexpected embedding response from Hugging Face");
    }
    return row as number[];
  });

  const dimensions = matrix[0].length;
  const pooled = new Array<number>(dimensions).fill(0);

  for (const row of matrix) {
    for (let i = 0; i < dimensions; i++) {
      pooled[i] += row[i] ?? 0;
    }
  }

  return pooled.map((value) => value / matrix.length);
}

export class HuggingFaceEmbeddingProvider implements EmbeddingProvider {
  readonly provider = "huggingface";
  readonly model = env.EMBEDDING_MODEL;
  readonly dimensions = env.EMBEDDING_DIMENSIONS;

  private readonly client: InferenceClient;

  constructor() {
    if (!env.HF_TOKEN) {
      throw new Error(
        "HF_TOKEN is not set but EMBEDDING_PROVIDER is 'huggingface'",
      );
    }

    this.client = new InferenceClient(env.HF_TOKEN);
  }

  async generateEmbedding(
    text: string,
    inputType?: EmbeddingInputType,
  ): Promise<number[]> {
    const inputs = applyInputPrefix(this.model, text, inputType);

    const result = await this.client.featureExtraction({
      model: this.model,
      inputs,
    });

    const vector = toVector(result);

    if (vector.length !== this.dimensions) {
      throw new Error(
        `Embedding dimension mismatch: expected ${this.dimensions}, got ${vector.length}`,
      );
    }

    return vector;
  }
}
