import { env } from "../../../config/env.js";
import { GroqLlmProvider } from "./groq.provider.js";
import { HuggingFaceLlmProvider } from "./huggingface.provider.js";
import type { LlmProvider } from "./llm-provider.js";

export function createLlmProvider(): LlmProvider {
  switch (env.LLM_PROVIDER) {
    case "groq":
      return new GroqLlmProvider();

    case "huggingface":
      return new HuggingFaceLlmProvider();

    default:
      throw new Error(`Unsupported LLM provider: ${env.LLM_PROVIDER}`);
  }
}
