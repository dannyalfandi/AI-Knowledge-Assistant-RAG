import { beforeEach, describe, expect, it, vi } from "vitest";

import * as feedbackService from "../../src/modules/feedback/feedback.service.js";
import * as feedbackRepository from "../../src/modules/feedback/feedback.repository.js";
import { BadRequestError, NotFoundError } from "../../src/utils/errors.js";

vi.mock("../../src/modules/feedback/feedback.repository.js", () => ({
  findMessageForUser: vi.fn(),
  findFeedback: vi.fn(),
  upsertFeedback: vi.fn(),
}));

const repo = vi.mocked(feedbackRepository);

const USER_ID = "11111111-1111-1111-1111-111111111111";
const MESSAGE_ID = "22222222-2222-2222-2222-222222222222";

const savedFeedback = {
  id: "fb-1",
  messageId: MESSAGE_ID,
  type: "POSITIVE" as const,
  comment: null,
  createdAt: new Date("2026-09-08T00:00:00.000Z"),
  updatedAt: new Date("2026-09-08T00:00:00.000Z"),
};

beforeEach(() => {
  vi.clearAllMocks();
});

describe("upsertFeedback", () => {
  it("throws NotFoundError and does not write when the message is not in the user's conversation", async () => {
    repo.findMessageForUser.mockResolvedValue(null);

    await expect(
      feedbackService.upsertFeedback(USER_ID, MESSAGE_ID, { type: "POSITIVE" }),
    ).rejects.toBeInstanceOf(NotFoundError);

    expect(repo.upsertFeedback).not.toHaveBeenCalled();
  });

  it("rejects feedback on a USER message with a 400", async () => {
    repo.findMessageForUser.mockResolvedValue({
      id: MESSAGE_ID,
      role: "USER",
    } as never);

    await expect(
      feedbackService.upsertFeedback(USER_ID, MESSAGE_ID, { type: "NEGATIVE" }),
    ).rejects.toBeInstanceOf(BadRequestError);

    expect(repo.upsertFeedback).not.toHaveBeenCalled();
  });

  it("leaves the comment untouched when the request carries only a type", async () => {
    repo.findMessageForUser.mockResolvedValue({
      id: MESSAGE_ID,
      role: "ASSISTANT",
    } as never);
    repo.upsertFeedback.mockResolvedValue(savedFeedback as never);

    const result = await feedbackService.upsertFeedback(USER_ID, MESSAGE_ID, {
      type: "POSITIVE",
    });

    // `comment` stays undefined rather than becoming null, so flipping a
    // rating does not wipe a comment the user wrote earlier.
    expect(repo.upsertFeedback).toHaveBeenCalledWith(USER_ID, MESSAGE_ID, {
      type: "POSITIVE",
      comment: undefined,
    });
    expect(result).toBe(savedFeedback);
  });

  it("passes an updated type and comment through to the repository", async () => {
    repo.findMessageForUser.mockResolvedValue({
      id: MESSAGE_ID,
      role: "ASSISTANT",
    } as never);
    repo.upsertFeedback.mockResolvedValue(savedFeedback as never);

    await feedbackService.upsertFeedback(USER_ID, MESSAGE_ID, {
      type: "NEGATIVE",
      comment: "jawabannya kurang lengkap",
    });

    expect(repo.upsertFeedback).toHaveBeenCalledWith(USER_ID, MESSAGE_ID, {
      type: "NEGATIVE",
      comment: "jawabannya kurang lengkap",
    });
  });
});

describe("getMyFeedback", () => {
  it("throws NotFoundError when the user has not given feedback yet", async () => {
    repo.findMessageForUser.mockResolvedValue({
      id: MESSAGE_ID,
      role: "ASSISTANT",
    } as never);
    repo.findFeedback.mockResolvedValue(null);

    await expect(
      feedbackService.getMyFeedback(USER_ID, MESSAGE_ID),
    ).rejects.toBeInstanceOf(NotFoundError);
  });

  it("returns the stored feedback when it exists", async () => {
    repo.findMessageForUser.mockResolvedValue({
      id: MESSAGE_ID,
      role: "ASSISTANT",
    } as never);
    repo.findFeedback.mockResolvedValue(savedFeedback as never);

    await expect(
      feedbackService.getMyFeedback(USER_ID, MESSAGE_ID),
    ).resolves.toBe(savedFeedback);
  });
});
