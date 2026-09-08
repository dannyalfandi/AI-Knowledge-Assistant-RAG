import prisma from "../../config/database.js";

export async function countUsers() {
  return prisma.user.count();
}

export async function countConversations() {
  return prisma.conversation.count();
}

export async function countDocumentsByStatus() {
  return prisma.document.groupBy({
    by: ["status"],
    _count: { _all: true },
  });
}

export async function countMessagesByRole() {
  return prisma.message.groupBy({
    by: ["role"],
    _count: { _all: true },
  });
}

export async function countFeedbackByType() {
  return prisma.feedback.groupBy({
    by: ["type"],
    _count: { _all: true },
  });
}
