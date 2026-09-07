import { getOpenAIClient } from "../../../config/openai.js";
import { env } from "../../../config/env.js";
import type {
  EmbeddingInputType,
  EmbeddingProvider,
} from "./embedding-provider.js";

export class OpenAIEmbeddingProvider implements EmbeddingProvider {
  readonly provider = "openai";
  readonly model = env.EMBEDDING_MODEL;
  readonly dimensions = env.EMBEDDING_DIMENSIONS;

  async generateEmbedding(
    text: string,
    _inputType?: EmbeddingInputType,
  ): Promise<number[]> {
    // OpenAI embedding models are symmetric and need no query/passage prefix.
    const response = await getOpenAIClient().embeddings.create({
      model: this.model,
      input: text,
      dimensions: this.dimensions,
    });

    const vector = response.data[0]?.embedding;

    if (!vector || vector.length !== this.dimensions) {
      throw new Error(
        `Embedding dimension mismatch: expected ${this.dimensions}, got ${vector?.length ?? 0}`,
      );
    }

    return vector;
  }
}
