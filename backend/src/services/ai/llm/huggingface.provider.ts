import { InferenceClient } from "@huggingface/inference";

import { env } from "../../../config/env.js";

type HfChatMessages = Parameters<InferenceClient["chatCompletion"]>[0]["messages"];
import {
  DEFAULT_COMPLETION_MAX_TOKENS,
  DEFAULT_COMPLETION_TEMPERATURE,
  type CompletionOptions,
  type CompletionResult,
  type LlmMessage,
  type LlmProvider,
} from "./llm-provider.js";

/**
 * Hugging Face Inference `chatCompletion` follows the OpenAI response shape
 * (`choices[].message.content`, `usage`), so the mapping here mirrors the Groq
 * provider — only the client and method name differ.
 */
export class HuggingFaceLlmProvider implements LlmProvider {
  readonly provider = "huggingface";
  readonly model = env.LLM_MODEL;

  private readonly client: InferenceClient;

  constructor() {
    if (!env.HF_TOKEN) {
      throw new Error("HF_TOKEN is not set but LLM_PROVIDER is 'huggingface'");
    }

    this.client = new InferenceClient(env.HF_TOKEN);
  }

  async generateCompletion(
    messages: LlmMessage[],
    options?: CompletionOptions,
  ): Promise<CompletionResult> {
    const response = await this.client.chatCompletion({
      model: this.model,
      // LlmMessage is a strict subset of HF's message type (which carries an
      // index signature for tool-calling fields we don't use).
      messages: messages as unknown as HfChatMessages,
      temperature: options?.temperature ?? DEFAULT_COMPLETION_TEMPERATURE,
      max_tokens: options?.maxTokens ?? DEFAULT_COMPLETION_MAX_TOKENS,
    });

    const choice = response.choices[0];
    const content = choice?.message?.content?.trim();

    if (!content) {
      throw new Error("Hugging Face returned an empty completion");
    }

    return {
      content,
      provider: this.provider,
      model: this.model,
      finishReason: choice?.finish_reason ?? null,
      usage: response.usage
        ? {
            promptTokens: response.usage.prompt_tokens,
            completionTokens: response.usage.completion_tokens,
            totalTokens: response.usage.total_tokens,
          }
        : null,
    };
  }
}
