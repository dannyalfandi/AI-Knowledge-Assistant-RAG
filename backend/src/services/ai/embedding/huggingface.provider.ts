import { InferenceClient } from "@huggingface/inference";

import { env } from "../../../config/env.js";
import { applyInputPrefix } from "./embedding-model-config.js";
import type {
  EmbeddingInputType,
  EmbeddingProvider,
} from "./embedding-provider.js";

function toVector(result: unknown): number[] {
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

    // TEMP DIAGNOSTIC — remove after embedding pipeline is confirmed working.
    console.error("[HF][request]", {
      model: this.model,
      inputType: inputType ?? null,
      inputPreview: inputs.slice(0, 80),
      inputLength: inputs.length,
    });

    let result: unknown;

    try {
      result = await this.client.featureExtraction({
        model: this.model,
        inputs,
      });
    } catch (error) {
      // TEMP DIAGNOSTIC — dump whatever the HF client exposes about the failure.
      const anyError = error as Record<string, unknown>;
      console.error("[HF][error]", {
        name: error instanceof Error ? error.name : typeof error,
        message: error instanceof Error ? error.message : String(error),
        status: anyError?.status ?? anyError?.statusCode,
        httpRequest: anyError?.httpRequest,
        httpResponse: anyError?.httpResponse,
        body: anyError?.body,
        ownProps: Object.getOwnPropertyNames(anyError ?? {}),
      });
      throw error;
    }

    // TEMP DIAGNOSTIC — describe the raw response shape.
    console.error("[HF][response]", {
      isArray: Array.isArray(result),
      length: Array.isArray(result) ? result.length : undefined,
      firstElementType: Array.isArray(result) ? typeof result[0] : undefined,
      firstElementIsArray: Array.isArray(result)
        ? Array.isArray((result as unknown[])[0])
        : undefined,
      preview: JSON.stringify(result).slice(0, 300),
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
