import { beforeEach, describe, expect, it, vi } from "vitest";

import * as adminService from "../../src/modules/admin/admin.service.js";
import * as adminRepository from "../../src/modules/admin/admin.repository.js";

vi.mock("../../src/modules/admin/admin.repository.js", () => ({
  countUsers: vi.fn(),
  countConversations: vi.fn(),
  countDocumentsByStatus: vi.fn(),
  countMessagesByRole: vi.fn(),
  countFeedbackByType: vi.fn(),
}));

const repo = vi.mocked(adminRepository);

function row<K extends string>(key: K, value: string, count: number) {
  return { [key]: value, _count: { _all: count } } as Record<K, string> & {
    _count: { _all: number };
  };
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe("getDashboard", () => {
  it("aggregates every metric and derives totals from the groupBy rows", async () => {
    repo.countUsers.mockResolvedValue(12);
    repo.countConversations.mockResolvedValue(88);
    repo.countDocumentsByStatus.mockResolvedValue([
      row("status", "PENDING", 1),
      row("status", "INDEXED", 37),
      row("status", "FAILED", 2),
    ] as never);
    repo.countMessagesByRole.mockResolvedValue([
      row("role", "USER", 214),
      row("role", "ASSISTANT", 209),
    ] as never);
    repo.countFeedbackByType.mockResolvedValue([
      row("type", "POSITIVE", 22),
      row("type", "NEGATIVE", 8),
    ] as never);

    const result = await adminService.getDashboard();

    expect(result).toEqual({
      users: { total: 12 },
      documents: {
        total: 40,
        byStatus: { PENDING: 1, PROCESSING: 0, INDEXED: 37, FAILED: 2 },
      },
      conversations: { total: 88 },
      questions: { asked: 214, answered: 209 },
      feedback: { total: 30, positive: 22, negative: 8 },
    });
  });

  it("fills missing groupBy buckets with zero", async () => {
    repo.countUsers.mockResolvedValue(0);
    repo.countConversations.mockResolvedValue(0);
    repo.countDocumentsByStatus.mockResolvedValue([] as never);
    repo.countMessagesByRole.mockResolvedValue([
      row("role", "USER", 3),
    ] as never);
    repo.countFeedbackByType.mockResolvedValue([] as never);

    const result = await adminService.getDashboard();

    expect(result.documents).toEqual({
      total: 0,
      byStatus: { PENDING: 0, PROCESSING: 0, INDEXED: 0, FAILED: 0 },
    });
    expect(result.questions).toEqual({ asked: 3, answered: 0 });
    expect(result.feedback).toEqual({ total: 0, positive: 0, negative: 0 });
  });

  it("runs the five repository queries in parallel", async () => {
    repo.countUsers.mockResolvedValue(0);
    repo.countConversations.mockResolvedValue(0);
    repo.countDocumentsByStatus.mockResolvedValue([] as never);
    repo.countMessagesByRole.mockResolvedValue([] as never);
    repo.countFeedbackByType.mockResolvedValue([] as never);

    await adminService.getDashboard();

    expect(repo.countUsers).toHaveBeenCalledOnce();
    expect(repo.countConversations).toHaveBeenCalledOnce();
    expect(repo.countDocumentsByStatus).toHaveBeenCalledOnce();
    expect(repo.countMessagesByRole).toHaveBeenCalledOnce();
    expect(repo.countFeedbackByType).toHaveBeenCalledOnce();
  });
});
