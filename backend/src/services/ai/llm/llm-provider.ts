export type LlmRole = "system" | "user" | "assistant";

export interface LlmMessage {
  role: LlmRole;
  content: string;
}

export interface CompletionOptions {
  temperature?: number;
  maxTokens?: number;
}

export interface CompletionUsage {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
}

export interface CompletionResult {
  content: string;
  provider: string;
  model: string;
  finishReason: string | null;
  usage: CompletionUsage | null;
}

export interface LlmProvider {
  readonly provider: string;
  readonly model: string;

  generateCompletion(
    messages: LlmMessage[],
    options?: CompletionOptions,
  ): Promise<CompletionResult>;
}

export const DEFAULT_COMPLETION_TEMPERATURE = 0.2;
export const DEFAULT_COMPLETION_MAX_TOKENS = 1024;
