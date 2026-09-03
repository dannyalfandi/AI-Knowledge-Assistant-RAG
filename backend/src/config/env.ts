import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.string().min(1),

  JWT_SECRET: z.string().min(32),

  JWT_EXPIRES_IN: z.string().default("1h"),
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error("Invalid environment variables:");
  console.error(parsedEnv.error.format());

  process.exit(1);
}

export const env = parsedEnv.data;
