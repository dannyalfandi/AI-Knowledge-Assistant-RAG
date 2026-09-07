import prisma from "../../config/database.js";

const conversationSummarySelect = {
  id: true,
  title: true,
  createdAt: true,
  updatedAt: true,
  _count: { select: { messages: true } },
} as const;

export async function createConversation(userId: string, title: string | null) {
  return prisma.conversation.create({
    data: {
      userId,
      title,
    },
    select: conversationSummarySelect,
  });
}

export async function listConversations(
  userId: string,
  { skip, take }: { skip: number; take: number },
) {
  return prisma.conversation.findMany({
    where: { userId },
    orderBy: { updatedAt: "desc" },
    skip,
    take,
    select: conversationSummarySelect,
  });
}

export async function countConversations(userId: string) {
  return prisma.conversation.count({
    where: { userId },
  });
}

export async function findConversationForUser(id: string, userId: string) {
  return prisma.conversation.findFirst({
    where: { id, userId },
    select: { id: true },
  });
}

export async function findConversationWithMessages(id: string, userId: string) {
  return prisma.conversation.findFirst({
    where: { id, userId },
    select: {
      id: true,
      title: true,
      createdAt: true,
      updatedAt: true,
      messages: {
        orderBy: { createdAt: "asc" },
        select: {
          id: true,
          role: true,
          content: true,
          createdAt: true,
        },
      },
    },
  });
}

export async function deleteConversationForUser(id: string, userId: string) {
  const result = await prisma.conversation.deleteMany({
    where: { id, userId },
  });

  return result.count;
}

export async function createUserMessage(conversationId: string, content: string) {
  return prisma.$transaction(async (tx) => {
    const message = await tx.message.create({
      data: {
        conversationId,
        role: "USER",
        content,
      },
      select: {
        id: true,
        conversationId: true,
        role: true,
        content: true,
        createdAt: true,
      },
    });

    await tx.conversation.update({
      where: { id: conversationId },
      data: {},
    });

    return message;
  });
}
