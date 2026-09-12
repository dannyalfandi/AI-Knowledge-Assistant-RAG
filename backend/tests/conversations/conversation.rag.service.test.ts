import { beforeEach, describe, expect, it, vi } from "vitest";

import { NOT_FOUND_MESSAGE } from "../../src/modules/conversations/conversation.rag.prompt.js";
import * as conversationRagService from "../../src/modules/conversations/conversation.rag.service.js";
import * as conversationRepository from "../../src/modules/conversations/conversation.repository.js";
import * as searchService from "../../src/modules/search/search.service.js";
import * as llmService from "../../src/services/ai/llm/llm.service.js";
import { NotFoundError } from "../../src/utils/errors.js";

vi.mock("../../src/modules/conversations/conversation.repository.js", () => ({
  findConversationForUser: vi.fn(),
  createUserMessage: vi.fn(),
  createExchange: vi.fn(),
}));

vi.mock("../../src/modules/search/search.service.js", () => ({
  semanticSearch: vi.fn(),
}));

vi.mock("../../src/services/ai/llm/llm.service.js", () => ({
  generateCompletion: vi.fn(),
}));

const repo = vi.mocked(conversationRepository);
const search = vi.mocked(searchService);
const llm = vi.mocked(llmService);

const USER_ID = "11111111-1111-1111-1111-111111111111";
const CONVERSATION_ID = "22222222-2222-2222-2222-222222222222";

const userMessage = {
  id: "user-msg",
  conversationId: CONVERSATION_ID,
  role: "USER",
  content: "q",
  createdAt: new Date("2026-09-08T00:00:00.000Z"),
};

const assistantMessage = {
  id: "assistant-msg",
  conversationId: CONVERSATION_ID,
  role: "ASSISTANT",
  content: "a",
  createdAt: new Date("2026-09-08T00:00:01.000Z"),
};

const chunk = {
  chunkId: "chunk-1",
  documentId: "doc-1",
  documentName: "Refund.pdf",
  pageNumber: 2,
  chunkIndex: 5,
  content: "Refund maksimal 7 hari.",
  similarityScore: 0.8,
};

/** A conversation that already has a title, so no auto-title is generated. */
function titledConversation() {
  return {
    id: CONVERSATION_ID,
    title: "Judul yang sudah ada",
    _count: { messages: 2 },
  };
}

/** A freshly created conversation: untitled and still empty. */
function untitledEmptyConversation() {
  return {
    id: CONVERSATION_ID,
    title: null,
    _count: { messages: 0 },
  };
}

function retrievalWith(results: unknown[]) {
  return {
    query: "q",
    provider: "huggingface",
    model: "intfloat/multilingual-e5-small",
    topK: 5,
    results,
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  repo.createExchange.mockResolvedValue({
    userMessage,
    assistantMessage,
  } as never);
});

describe("askInConversation", () => {
  it("throws NotFoundError and saves nothing when the conversation is not the user's", async () => {
    repo.findConversationForUser.mockResolvedValue(null);

    await expect(
      conversationRagService.askInConversation(USER_ID, CONVERSATION_ID, {
        question: "q",
      }),
    ).rejects.toBeInstanceOf(NotFoundError);

    expect(repo.createExchange).not.toHaveBeenCalled();
    expect(search.semanticSearch).not.toHaveBeenCalled();
  });

  it("short-circuits without calling the LLM when retrieval returns no chunks", async () => {
    repo.findConversationForUser.mockResolvedValue(
      titledConversation() as never,
    );
    search.semanticSearch.mockResolvedValue(retrievalWith([]) as never);

    const result = await conversationRagService.askInConversation(
      USER_ID,
      CONVERSATION_ID,
      { question: "q" },
    );

    expect(llm.generateCompletion).not.toHaveBeenCalled();
    expect(result.answer).toBe(NOT_FOUND_MESSAGE);
    expect(result.sources).toEqual([]);
    expect(result.llm).toBeNull();
    expect(result.retrieval.matchCount).toBe(0);
    expect(repo.createExchange).toHaveBeenCalledWith(
      CONVERSATION_ID,
      "q",
      NOT_FOUND_MESSAGE,
      [],
      undefined,
    );
  });

  it("retrieves, grounds, calls the LLM, and persists every chunk as a source", async () => {
    repo.findConversationForUser.mockResolvedValue(
      titledConversation() as never,
    );
    search.semanticSearch.mockResolvedValue(retrievalWith([chunk]) as never);
    llm.generateCompletion.mockResolvedValue({
      content: "Refund maksimal 7 hari.",
      provider: "groq",
      model: "openai/gpt-oss-120b",
      finishReason: "stop",
      usage: { promptTokens: 100, completionTokens: 10, totalTokens: 110 },
    } as never);

    const result = await conversationRagService.askInConversation(
      USER_ID,
      CONVERSATION_ID,
      { question: "berapa lama refund?" },
    );

    expect(llm.generateCompletion).toHaveBeenCalledOnce();
    const [messages] = llm.generateCompletion.mock.calls[0] as [
      { role: string; content: string }[],
    ];
    expect(messages[0].role).toBe("system");
    expect(messages[0].content).toContain("Refund maksimal 7 hari.");
    expect(messages[1]).toEqual({
      role: "user",
      content: "berapa lama refund?",
    });

    expect(repo.createExchange).toHaveBeenCalledWith(
      CONVERSATION_ID,
      "berapa lama refund?",
      "Refund maksimal 7 hari.",
      [{ documentChunkId: "chunk-1", similarityScore: 0.8 }],
      undefined,
    );

    expect(result.answer).toBe("Refund maksimal 7 hari.");
    expect(result.sources).toHaveLength(1);
    expect(result.sources[0]).toMatchObject({
      documentChunkId: "chunk-1",
      documentName: "Refund.pdf",
      pageNumber: 2,
      similarityScore: 0.8,
    });
    expect(result.llm).toMatchObject({
      provider: "groq",
      model: "openai/gpt-oss-120b",
      finishReason: "stop",
    });
    expect(result.retrieval).toEqual({
      provider: "huggingface",
      model: "intfloat/multilingual-e5-small",
      topK: 5,
      matchCount: 1,
    });
  });

  it("wraps an LLM failure in a 502 AppError and persists nothing", async () => {
    repo.findConversationForUser.mockResolvedValue(
      titledConversation() as never,
    );
    search.semanticSearch.mockResolvedValue(retrievalWith([chunk]) as never);
    llm.generateCompletion.mockRejectedValue(new Error("groq 500"));

    await expect(
      conversationRagService.askInConversation(USER_ID, CONVERSATION_ID, {
        question: "q",
      }),
    ).rejects.toMatchObject({ statusCode: 502 });

    // Nothing is written on failure, so a retry cannot duplicate the question.
    expect(repo.createExchange).not.toHaveBeenCalled();
  });
});

describe("auto-title", () => {
  beforeEach(() => {
    search.semanticSearch.mockResolvedValue(retrievalWith([chunk]) as never);
    llm.generateCompletion.mockResolvedValue({
      content: "Refund maksimal 7 hari.",
      provider: "groq",
      model: "openai/gpt-oss-120b",
      finishReason: "stop",
      usage: null,
    } as never);
  });

  /** The title handed to `createExchange`, which writes it in the same transaction. */
  function titleArgument() {
    return repo.createExchange.mock.calls[0]?.[4];
  }

  it("names an untitled, empty conversation after its first question", async () => {
    repo.findConversationForUser.mockResolvedValue(
      untitledEmptyConversation() as never,
    );

    await conversationRagService.askInConversation(USER_ID, CONVERSATION_ID, {
      question: "Berapa lama proses refund?",
    });

    expect(titleArgument()).toBe("Berapa lama proses refund?");
  });

  it("truncates a long first question at a word boundary", async () => {
    repo.findConversationForUser.mockResolvedValue(
      untitledEmptyConversation() as never,
    );

    await conversationRagService.askInConversation(USER_ID, CONVERSATION_ID, {
      question:
        "Bagaimana prosedur pengajuan refund untuk produk elektronik yang rusak?",
    });

    const title = titleArgument() as string;
    expect(title.endsWith("...")).toBe(true);
    expect(title.length).toBeLessThanOrEqual(53);
  });

  it("never replaces a title that already exists", async () => {
    repo.findConversationForUser.mockResolvedValue({
      id: CONVERSATION_ID,
      title: "Judul yang sudah ada",
      _count: { messages: 0 },
    } as never);

    await conversationRagService.askInConversation(USER_ID, CONVERSATION_ID, {
      question: "pertanyaan baru",
    });

    expect(titleArgument()).toBeUndefined();
  });

  it("leaves a later question in an untitled conversation alone", async () => {
    // Untitled but not empty: the title was cleared or the first exchange
    // predates this feature. Naming it from a mid-conversation question would
    // be misleading.
    repo.findConversationForUser.mockResolvedValue({
      id: CONVERSATION_ID,
      title: null,
      _count: { messages: 4 },
    } as never);

    await conversationRagService.askInConversation(USER_ID, CONVERSATION_ID, {
      question: "pertanyaan lanjutan",
    });

    expect(titleArgument()).toBeUndefined();
  });

  it("also names the conversation when retrieval found nothing", async () => {
    repo.findConversationForUser.mockResolvedValue(
      untitledEmptyConversation() as never,
    );
    search.semanticSearch.mockResolvedValue(retrievalWith([]) as never);

    await conversationRagService.askInConversation(USER_ID, CONVERSATION_ID, {
      question: "Berapa lama proses refund?",
    });

    // The short-circuit path stores an exchange too, so it must name the
    // conversation as well.
    expect(titleArgument()).toBe("Berapa lama proses refund?");
  });
});
