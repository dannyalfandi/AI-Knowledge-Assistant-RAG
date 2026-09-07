import { createLlmProvider } from "./llm-provider.factory.js";
import type {
  CompletionOptions,
  CompletionResult,
  LlmMessage,
  LlmProvider,
} from "./llm-provider.js";

let provider: LlmProvider | null = null;

export function getLlmProvider(): LlmProvider {
  if (!provider) {
    provider = createLlmProvider();
  }

  return provider;
}

export async function generateCompletion(
  messages: LlmMessage[],
  options?: CompletionOptions,
): Promise<CompletionResult> {
  return getLlmProvider().generateCompletion(messages, options);
}
