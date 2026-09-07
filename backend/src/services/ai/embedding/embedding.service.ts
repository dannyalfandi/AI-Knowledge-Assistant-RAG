import { createEmbeddingProvider } from "./embedding-provider.factory.js";
import type {
  EmbeddingInputType,
  EmbeddingProvider,
} from "./embedding-provider.js";

let provider: EmbeddingProvider | null = null;

export function getEmbeddingProvider(): EmbeddingProvider {
  if (!provider) {
    provider = createEmbeddingProvider();
  }

  return provider;
}

export async function generateEmbedding(
  text: string,
  inputType?: EmbeddingInputType,
): Promise<number[]> {
  return getEmbeddingProvider().generateEmbedding(text, inputType);
}
