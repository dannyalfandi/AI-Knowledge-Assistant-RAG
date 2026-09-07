import type { EmbeddingInputType } from "./embedding-provider.js";

interface ModelInputPrefixes {
  query: string;
  passage: string;
}

/**
 * The E5 model family is trained with asymmetric input prefixes ("query: " for
 * search queries, "passage: " for indexed text) and produces near-random
 * similarity scores without them. Only models listed here get a prefix; every
 * other model (all-MiniLM, OpenAI embeddings, ...) is embedded verbatim.
 */
const MODEL_INPUT_PREFIXES: Record<string, ModelInputPrefixes> = {
  "intfloat/multilingual-e5-small": { query: "query: ", passage: "passage: " },
  "intfloat/multilingual-e5-base": { query: "query: ", passage: "passage: " },
  "intfloat/multilingual-e5-large": { query: "query: ", passage: "passage: " },
  "intfloat/e5-small-v2": { query: "query: ", passage: "passage: " },
  "intfloat/e5-base-v2": { query: "query: ", passage: "passage: " },
  "intfloat/e5-large-v2": { query: "query: ", passage: "passage: " },
};

export function getInputPrefix(
  model: string,
  inputType: EmbeddingInputType | undefined,
): string {
  if (!inputType) {
    return "";
  }

  return MODEL_INPUT_PREFIXES[model]?.[inputType] ?? "";
}

export function applyInputPrefix(
  model: string,
  text: string,
  inputType: EmbeddingInputType | undefined,
): string {
  return `${getInputPrefix(model, inputType)}${text}`;
}
