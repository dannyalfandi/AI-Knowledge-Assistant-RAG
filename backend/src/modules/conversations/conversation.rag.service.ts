import { generateCompletion } from "../../services/ai/llm/llm.service.js";
import { semanticSearch } from "../search/search.service.js";
import { AppError, NotFoundError } from "../../utils/errors.js";
import { buildRagMessages, NOT_FOUND_MESSAGE } from "./conversation.rag.prompt.js";
import { buildAutoTitle } from "./conversation.title.js";
import * as conversationRepository from "./conversation.repository.js";
import type { AskInput } from "./conversation.validation.js";

/**
 * Number of chunks pulled from semantic search into the LLM context. Named
 * constant rather than a magic number so it can move to env later; it is a
 * retrieval size, not a relevance threshold.
 */
export const RAG_TOP_K = 5;

interface MessagePayload {
  id: string;
  role: string;
  content: string;
  createdAt: Date;
}

export interface AskSource {
  documentChunkId: string;
  documentId: string;
  documentName: string;
  pageNumber: number | null;
  chunkIndex: number;
  content: string;
  similarityScore: number;
}

export interface AskResult {
  conversationId: string;
  question: string;
  answer: string;
  userMessage: MessagePayload;
  assistantMessage: MessagePayload;
  sources: AskSource[];
  retrieval: {
    provider: string;
    model: string;
    topK: number;
    matchCount: number;
  };
  llm: {
    provider: string;
    model: string;
    finishReason: string | null;
    usage: {
      promptTokens: number;
      completionTokens: number;
      totalTokens: number;
    } | null;
  } | null;
}

function toMessagePayload(message: {
  id: string;
  role: string;
  content: string;
  createdAt: Date;
}): MessagePayload {
  return {
    id: message.id,
    role: message.role,
    content: message.content,
    createdAt: message.createdAt,
  };
}

export async function askInConversation(
  userId: string,
  conversationId: string,
  input: AskInput,
): Promise<AskResult> {
  const conversation = await conversationRepository.findConversationForUser(
    conversationId,
    userId,
  );

  if (!conversation) {
    throw new NotFoundError("Conversation not found");
  }

  const { question } = input;

  // Decided before anything is written: at this point a freshly created
  // conversation genuinely has no messages, because the ask flow stores the
  // question only alongside its answer. An existing title is never replaced,
  // whether it was set manually or generated from an earlier question.
  const autoTitle =
    conversation.title === null && conversation._count.messages === 0
      ? (buildAutoTitle(question) ?? undefined)
      : undefined;

  const retrieval = await semanticSearch({
    query: question,
    topK: RAG_TOP_K,
  });

  const sources: AskSource[] = retrieval.results.map((result) => ({
    documentChunkId: result.chunkId,
    documentId: result.documentId,
    documentName: result.documentName,
    pageNumber: result.pageNumber,
    chunkIndex: result.chunkIndex,
    content: result.content,
    similarityScore: result.similarityScore,
  }));

  const retrievalMeta = {
    provider: retrieval.provider,
    model: retrieval.model,
    topK: retrieval.topK,
    matchCount: retrieval.results.length,
  };

  // Nothing retrieved: there is nothing to ground on, so skip the LLM call and
  // return the not-found answer directly.
  if (sources.length === 0) {
    const exchange = await conversationRepository.createExchange(
      conversationId,
      question,
      NOT_FOUND_MESSAGE,
      [],
      autoTitle,
    );

    return {
      conversationId,
      question,
      answer: NOT_FOUND_MESSAGE,
      userMessage: toMessagePayload(exchange.userMessage),
      assistantMessage: toMessagePayload(exchange.assistantMessage),
      sources: [],
      retrieval: retrievalMeta,
      llm: null,
    };
  }

  const messages = buildRagMessages(question, retrieval.results);

  let completion;

  try {
    completion = await generateCompletion(messages);
  } catch (error) {
    // Nothing has been written yet: the question is only persisted alongside a
    // successful answer, so the client can retry without leaving a duplicate
    // question behind.
    throw new AppError(
      "Gagal mendapatkan jawaban dari LLM",
      502,
      error instanceof Error ? error.message : undefined,
    );
  }

  const exchange = await conversationRepository.createExchange(
    conversationId,
    question,
    completion.content,
    sources.map((source) => ({
      documentChunkId: source.documentChunkId,
      similarityScore: source.similarityScore,
    })),
    autoTitle,
  );

  return {
    conversationId,
    question,
    answer: completion.content,
    userMessage: toMessagePayload(exchange.userMessage),
    assistantMessage: toMessagePayload(exchange.assistantMessage),
    sources,
    retrieval: retrievalMeta,
    llm: {
      provider: completion.provider,
      model: completion.model,
      finishReason: completion.finishReason,
      usage: completion.usage,
    },
  };
}
