import {
  DocumentStatus,
  FeedbackType,
  MessageRole,
} from "../../generated/prisma/client.js";
import * as adminRepository from "./admin.repository.js";

interface GroupCountRow {
  _count: { _all: number };
}

function tallyByKey<T extends GroupCountRow>(
  rows: T[],
  getValue: (row: T) => string,
  allValues: readonly string[],
): Record<string, number> {
  const result: Record<string, number> = {};

  for (const value of allValues) {
    result[value] = 0;
  }

  for (const row of rows) {
    result[getValue(row)] = row._count._all;
  }

  return result;
}

function sum(values: number[]): number {
  return values.reduce((total, value) => total + value, 0);
}

export interface AdminDashboard {
  users: { total: number };
  documents: { total: number; byStatus: Record<string, number> };
  conversations: { total: number };
  questions: { asked: number; answered: number };
  feedback: { total: number; positive: number; negative: number };
}

export async function getDashboard(): Promise<AdminDashboard> {
  const [
    userCount,
    conversationCount,
    documentsByStatus,
    messagesByRole,
    feedbackByType,
  ] = await Promise.all([
    adminRepository.countUsers(),
    adminRepository.countConversations(),
    adminRepository.countDocumentsByStatus(),
    adminRepository.countMessagesByRole(),
    adminRepository.countFeedbackByType(),
  ]);

  const byStatus = tallyByKey(
    documentsByStatus,
    (row) => row.status,
    Object.values(DocumentStatus),
  );

  const byRole = tallyByKey(
    messagesByRole,
    (row) => row.role,
    Object.values(MessageRole),
  );

  const byType = tallyByKey(
    feedbackByType,
    (row) => row.type,
    Object.values(FeedbackType),
  );

  return {
    users: { total: userCount },
    documents: {
      total: sum(Object.values(byStatus)),
      byStatus,
    },
    conversations: { total: conversationCount },
    questions: {
      asked: byRole[MessageRole.USER],
      answered: byRole[MessageRole.ASSISTANT],
    },
    feedback: {
      total: sum(Object.values(byType)),
      positive: byType[FeedbackType.POSITIVE],
      negative: byType[FeedbackType.NEGATIVE],
    },
  };
}
