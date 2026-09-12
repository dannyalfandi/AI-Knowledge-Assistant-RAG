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

/**
 * Ownership check for a conversation, which also carries what the ask flow
 * needs to decide on an auto-title: the current title and whether the
 * conversation is still empty. Both ride along on the query that already runs,
 * so no extra round-trip is needed.
 */
export async function findConversationForUser(id: string, userId: string) {
  return prisma.conversation.findFirst({
    where: { id, userId },
    select: {
      id: true,
      title: true,
      _count: { select: { messages: true } },
    },
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
          // The reader's own feedback, so a reopened conversation shows what
          // they already rated instead of starting blank. Fetched with the
          // conversation rather than one request per message.
          feedbacks: {
            where: { userId },
            select: {
              id: true,
              type: true,
              comment: true,
              createdAt: true,
              updatedAt: true,
            },
          },
          // Citations are part of the answer, not an extra: an assistant
          // message must carry its sources whenever it is read back, not only
          // in the /ask response that produced it.
          sources: {
            orderBy: { similarityScore: "desc" },
            select: {
              similarityScore: true,
              documentChunk: {
                select: {
                  id: true,
                  content: true,
                  chunkIndex: true,
                  pageNumber: true,
                  document: {
                    select: { id: true, originalName: true },
                  },
                },
              },
            },
          },
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

export interface MessageSourceInput {
  documentChunkId: string;
  similarityScore: number;
}

const messageSelect = {
  id: true,
  conversationId: true,
  role: true,
  content: true,
  createdAt: true,
} as const;

/**
 * Persists one question/answer pair in a single transaction.
 *
 * The question is stored together with its answer rather than up front, so a
 * failed LLM call leaves no dangling USER message behind: retrying the same
 * question produces one exchange, not a duplicate question.
 *
 * `title` is written in the same transaction — the conversation row is already
 * being updated here to bump `updatedAt`, so naming it costs no extra query.
 * Omit it to leave the existing title alone.
 */
export async function createExchange(
  conversationId: string,
  question: string,
  answer: string,
  sources: MessageSourceInput[],
  title?: string,
) {
  return prisma.$transaction(async (tx) => {
    const userMessage = await tx.message.create({
      data: {
        conversationId,
        role: "USER",
        content: question,
      },
      select: messageSelect,
    });

    const assistantMessage = await tx.message.create({
      data: {
        conversationId,
        role: "ASSISTANT",
        content: answer,
      },
      select: messageSelect,
    });

    if (sources.length > 0) {
      await tx.messageSource.createMany({
        data: sources.map((source) => ({
          messageId: assistantMessage.id,
          documentChunkId: source.documentChunkId,
          similarityScore: source.similarityScore,
        })),
      });
    }

    await tx.conversation.update({
      where: { id: conversationId },
      data: title === undefined ? {} : { title },
    });

    return { userMessage, assistantMessage };
  });
}

