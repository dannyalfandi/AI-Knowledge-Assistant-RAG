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
    const conversation = { id: "c1", messages: [] };
    repo.findConversationWithMessages.mockResolvedValue(conversation as never);

    await expect(
      conversationService.getConversation(USER_ID, "c1"),
    ).resolves.toBe(conversation);
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
