import prisma from "../../config/database.js";

export async function findUserByEmailWithRole(email: string) {
  return prisma.user.findUnique({
    where: { email },
    include: { role: true },
  });
}
