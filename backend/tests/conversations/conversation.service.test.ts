import { beforeEach, describe, expect, it, vi } from "vitest";

import * as conversationService from "../../src/modules/conversations/conversation.service.js";
import * as conversationRepository from "../../src/modules/conversations/conversation.repository.js";
import { NotFoundError } from "../../src/utils/errors.js";

vi.mock("../../src/modules/conversations/conversation.repository.js", () => ({
  createConversation: vi.fn(),
  listConversations: vi.fn(),
  countConversations: vi.fn(),
  findConversationForUser: vi.fn(),
  findConversationWithMessages: vi.fn(),
  deleteConversationForUser: vi.fn(),
  createUserMessage: vi.fn(),
}));

const repo = vi.mocked(conversationRepository);

const USER_ID = "11111111-1111-1111-1111-111111111111";
const OTHER_CONVERSATION_ID = "22222222-2222-2222-2222-222222222222";

beforeEach(() => {
  vi.clearAllMocks();
});

describe("createConversation", () => {
  it("passes an explicit title through to the repository", async () => {
    repo.createConversation.mockResolvedValue({ id: "c1" } as never);

    await conversationService.createConversation(USER_ID, { title: "Refund Q&A" });

    expect(repo.createConversation).toHaveBeenCalledWith(USER_ID, "Refund Q&A");
  });

  it("stores null when no title is provided", async () => {
    repo.createConversation.mockResolvedValue({ id: "c1" } as never);

    await conversationService.createConversation(USER_ID, {});

    expect(repo.createConversation).toHaveBeenCalledWith(USER_ID, null);
  });
});

describe("listConversations", () => {
  it("scopes the query to the user and builds pagination meta", async () => {
    repo.listConversations.mockResolvedValue([{ id: "c1" }] as never);
    repo.countConversations.mockResolvedValue(47);

    const result = await conversationService.listConversations(USER_ID, {
      page: 2,
      limit: 10,
    });

    expect(repo.listConversations).toHaveBeenCalledWith(USER_ID, {
      skip: 10,
      take: 10,
    });
    expect(repo.countConversations).toHaveBeenCalledWith(USER_ID);
    expect(result.pagination).toEqual({
      page: 2,
      limit: 10,
      total: 47,
      totalPages: 5,
    });
  });

  it("reports zero pages when the user has no conversations", async () => {
    repo.listConversations.mockResolvedValue([] as never);
    repo.countConversations.mockResolvedValue(0);

    const result = await conversationService.listConversations(USER_ID, {
      page: 1,
      limit: 20,
    });

    expect(result.data).toEqual([]);
    expect(result.pagination.totalPages).toBe(0);
  });
});

describe("getConversation", () => {
  it("throws NotFoundError when the conversation is not owned by the user", async () => {
    repo.findConversationWithMessages.mockResolvedValue(null);

    await expect(
      conversationService.getConversation(USER_ID, OTHER_CONVERSATION_ID),
    ).rejects.toBeInstanceOf(NotFoundError);
  });

  it("returns the conversation with its messages when owned", async () => {
    const conversation = { id: "c1", title: "Refund", messages: [] };
    repo.findConversationWithMessages.mockResolvedValue(conversation as never);

    await expect(
      conversationService.getConversation(USER_ID, "c1"),
    ).resolves.toEqual({ id: "c1", title: "Refund", messages: [] });
  });

  it("flattens stored citations into the same shape /ask returns", async () => {
    repo.findConversationWithMessages.mockResolvedValue({
      id: "c1",
      messages: [
        {
          id: "m1",
          role: "ASSISTANT",
          content: "Refund maksimal 7 hari.",
          createdAt: new Date("2026-09-08T00:00:00.000Z"),
          feedbacks: [],
          sources: [
            {
              similarityScore: 0.81,
              documentChunk: {
                id: "chunk-1",
                content: "Refund maksimal 7 hari setelah barang diterima.",
                chunkIndex: 5,
                pageNumber: 4,
                document: { id: "doc-1", originalName: "Refund Policy.pdf" },
              },
            },
          ],
        },
      ],
    } as never);

    const result = await conversationService.getConversation(USER_ID, "c1");

    expect(result.messages[0].sources).toEqual([
      {
        documentChunkId: "chunk-1",
        documentId: "doc-1",
        documentName: "Refund Policy.pdf",
        pageNumber: 4,
        chunkIndex: 5,
        content: "Refund maksimal 7 hari setelah barang diterima.",
        similarityScore: 0.81,
      },
    ]);
  });

  it("exposes the reader's own feedback as a single object", async () => {
    repo.findConversationWithMessages.mockResolvedValue({
      id: "c1",
      messages: [
        {
          id: "m1",
          role: "ASSISTANT",
          content: "Refund maksimal 7 hari.",
          createdAt: new Date("2026-09-08T00:00:00.000Z"),
          sources: [],
          feedbacks: [
            {
              id: "fb-1",
              type: "NEGATIVE",
              comment: "kurang lengkap",
              createdAt: new Date("2026-09-08T00:00:00.000Z"),
              updatedAt: new Date("2026-09-08T00:00:00.000Z"),
            },
          ],
        },
      ],
    } as never);

    const result = await conversationService.getConversation(USER_ID, "c1");

    expect(result.messages[0].myFeedback).toMatchObject({
      id: "fb-1",
      type: "NEGATIVE",
      comment: "kurang lengkap",
    });
  });

  it("reports myFeedback as null when the reader has not rated a message", async () => {
    repo.findConversationWithMessages.mockResolvedValue({
      id: "c1",
      messages: [
        {
          id: "m1",
          role: "ASSISTANT",
          content: "a",
          createdAt: new Date("2026-09-08T00:00:00.000Z"),
          sources: [],
          feedbacks: [],
        },
      ],
    } as never);

    const result = await conversationService.getConversation(USER_ID, "c1");

    expect(result.messages[0].myFeedback).toBeNull();
  });

  it("returns an empty source list for a USER message", async () => {
    repo.findConversationWithMessages.mockResolvedValue({
      id: "c1",
      messages: [
        {
          id: "m1",
          role: "USER",
          content: "berapa lama refund?",
          createdAt: new Date("2026-09-08T00:00:00.000Z"),
          sources: [],
          feedbacks: [],
        },
      ],
    } as never);

    const result = await conversationService.getConversation(USER_ID, "c1");

    expect(result.messages[0].sources).toEqual([]);
  });
});

describe("deleteConversation", () => {
  it("throws NotFoundError when nothing was deleted", async () => {
    repo.deleteConversationForUser.mockResolvedValue(0);

    await expect(
      conversationService.deleteConversation(USER_ID, OTHER_CONVERSATION_ID),
    ).rejects.toBeInstanceOf(NotFoundError);
  });

  it("resolves when a row was deleted", async () => {
    repo.deleteConversationForUser.mockResolvedValue(1);

    await expect(
      conversationService.deleteConversation(USER_ID, "c1"),
    ).resolves.toBeUndefined();
  });
});

describe("addUserMessage", () => {
  it("refuses to add a message to a conversation the user does not own", async () => {
    repo.findConversationForUser.mockResolvedValue(null);

    await expect(
      conversationService.addUserMessage(USER_ID, OTHER_CONVERSATION_ID, {
        content: "hello",
      }),
    ).rejects.toBeInstanceOf(NotFoundError);

    expect(repo.createUserMessage).not.toHaveBeenCalled();
  });

  it("creates the message once ownership is verified", async () => {
    repo.findConversationForUser.mockResolvedValue({ id: "c1" } as never);
    repo.createUserMessage.mockResolvedValue({ id: "m1", role: "USER" } as never);

    await conversationService.addUserMessage(USER_ID, "c1", { content: "hello" });

    expect(repo.createUserMessage).toHaveBeenCalledWith("c1", "hello");
  });
});
