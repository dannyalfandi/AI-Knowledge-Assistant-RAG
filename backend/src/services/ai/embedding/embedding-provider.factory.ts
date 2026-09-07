import { env } from "../../../config/env.js";
import type { EmbeddingProvider } from "./embedding-provider.js";
import { HuggingFaceEmbeddingProvider } from "./huggingface.provider.js";
import { OpenAIEmbeddingProvider } from "./openai.provider.js";

export function createEmbeddingProvider(): EmbeddingProvider {
  switch (env.EMBEDDING_PROVIDER) {
    case "huggingface":
      return new HuggingFaceEmbeddingProvider();

    case "openai":
      return new OpenAIEmbeddingProvider();

    default:
      throw new Error(
        `Unsupported embedding provider: ${env.EMBEDDING_PROVIDER}`,
      );
  }
}
