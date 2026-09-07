import "dotenv/config";
import argon2 from "argon2";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../src/generated/prisma/client.js";

const connectionString = process.env.DATABASE_URL;

const adminEmail = process.env.SEED_ADMIN_EMAIL;

const adminPassword = process.env.SEED_ADMIN_PASSWORD;

const adminName = process.env.SEED_ADMIN_NAME ?? "Development Admin";

const userEmail = process.env.SEED_USER_EMAIL;

const userPassword = process.env.SEED_USER_PASSWORD;

const userName = process.env.SEED_USER_NAME ?? "Development User";

if (!connectionString) {
  throw new Error("DATABASE_URL is not defined");
}

const adapter = new PrismaPg({
  connectionString,
});

const prisma = new PrismaClient({
  adapter,
});

async function main() {
  console.log("Starting database seed...");

  // Create roles
  const adminRole = await prisma.role.upsert({
    where: {
      name: "ADMIN",
    },
    update: {},
    create: {
      name: "ADMIN",
    },
  });

  const userRole = await prisma.role.upsert({
    where: {
      name: "USER",
    },
    update: {},
    create: {
      name: "USER",
    },
  });

  console.log("Roles created:", {
    adminRole: adminRole.name,
    userRole: userRole.name,
  });

  if (!adminEmail || !adminPassword) {
    throw new Error("SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD must be defined");
  }
  // Create development admin
  const passwordHash = await argon2.hash(adminPassword);

  const adminUser = await prisma.user.upsert({
    where: {
      email: adminEmail,
    },
    update: {
      roleId: adminRole.id,
      name: adminName,
      isActive: true,
    },
    create: {
      roleId: adminRole.id,
      email: adminEmail,
      passwordHash,
      name: adminName,
      isActive: true,
    },
  });

  console.log("Development admin created:", {
    id: adminUser.id,
    email: adminUser.email,
    role: adminRole.name,
  });

  if (!userEmail || !userPassword) {
    throw new Error("SEED_USER_EMAIL and SEED_USER_PASSWORD must be defined");
  }

  // Create development user
  const userPasswordHash = await argon2.hash(userPassword);

  const user = await prisma.user.upsert({
    where: {
      email: userEmail,
    },
    update: {
      roleId: userRole.id,
      name: userName,
      isActive: true,
    },
    create: {
      roleId: userRole.id,
      email: userEmail,
      passwordHash: userPasswordHash,
      name: userName,
      isActive: true,
    },
  });

  console.log("Development user created:", {
    id: user.id,
    email: user.email,
    role: userRole.name,
  });

  console.log("Database seed completed successfully.");
}

main()
  .catch((error) => {
    console.error("Database seed failed:", error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
