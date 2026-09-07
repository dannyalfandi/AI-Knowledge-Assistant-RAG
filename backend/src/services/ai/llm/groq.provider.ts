import type OpenAI from "openai";

import { env } from "../../../config/env.js";
import { getGroqClient } from "../../../config/groq.js";
import {
  DEFAULT_COMPLETION_MAX_TOKENS,
  DEFAULT_COMPLETION_TEMPERATURE,
  type CompletionOptions,
  type CompletionResult,
  type LlmMessage,
  type LlmProvider,
} from "./llm-provider.js";

/**
 * Groq exposes an OpenAI-compatible Chat Completions API, so the `openai` SDK
 * works verbatim against it once the `baseURL` is swapped (see config/groq.ts).
 */
export class GroqLlmProvider implements LlmProvider {
  readonly provider = "groq";
  readonly model = env.LLM_MODEL;

  async generateCompletion(
    messages: LlmMessage[],
    options?: CompletionOptions,
  ): Promise<CompletionResult> {
    const response = await getGroqClient().chat.completions.create({
      model: this.model,
      messages: messages as OpenAI.Chat.Completions.ChatCompletionMessageParam[],
      temperature: options?.temperature ?? DEFAULT_COMPLETION_TEMPERATURE,
      max_tokens: options?.maxTokens ?? DEFAULT_COMPLETION_MAX_TOKENS,
    });

    const choice = response.choices[0];
    const content = choice?.message?.content?.trim();

    if (!content) {
      throw new Error("Groq returned an empty completion");
    }

    return {
      content,
      provider: this.provider,
      model: response.model || this.model,
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
