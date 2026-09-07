import "dotenv/config";
import { z } from "zod";

/**
 * Optional secret. An empty value in `.env` (`FOO=`) is normalized to "not set"
 * so the cross-field checks below can raise a specific message instead of a
 * generic "String must contain at least 1 character".
 */
const optionalSecret = z.preprocess(
  (value) => (value === "" ? undefined : value),
  z.string().min(1).optional(),
);

const envSchema = z
  .object({
    PORT: z.coerce.number().int().positive().default(3000),

    DATABASE_URL: z.string().min(1),

    JWT_SECRET: z.string().min(32),
    JWT_EXPIRES_IN: z.string().min(1),

    HF_TOKEN: optionalSecret,

    OPENAI_API_KEY: optionalSecret,

    GROQ_API_KEY: optionalSecret,

    EMBEDDING_PROVIDER: z.enum(["huggingface", "openai"]).default("huggingface"),
    EMBEDDING_MODEL: z.string().min(1).default("intfloat/multilingual-e5-small"),
    EMBEDDING_DIMENSIONS: z.coerce.number().int().positive().default(384),

    LLM_PROVIDER: z.enum(["groq", "huggingface"]).default("groq"),
    LLM_MODEL: z.string().min(1).default("openai/gpt-oss-120b"),
  })
  .superRefine((data, ctx) => {
    if (data.EMBEDDING_PROVIDER === "huggingface" && !data.HF_TOKEN) {
      ctx.addIssue({
        code: "custom",
        path: ["HF_TOKEN"],
        message: "HF_TOKEN wajib diisi kalau EMBEDDING_PROVIDER=huggingface",
      });
    }

    if (data.EMBEDDING_PROVIDER === "openai" && !data.OPENAI_API_KEY) {
      ctx.addIssue({
        code: "custom",
        path: ["OPENAI_API_KEY"],
        message: "OPENAI_API_KEY wajib diisi kalau EMBEDDING_PROVIDER=openai",
      });
    }

    if (data.LLM_PROVIDER === "groq" && !data.GROQ_API_KEY) {
      ctx.addIssue({
        code: "custom",
        path: ["GROQ_API_KEY"],
        message: "GROQ_API_KEY wajib diisi kalau LLM_PROVIDER=groq",
      });
    }

    if (data.LLM_PROVIDER === "huggingface" && !data.HF_TOKEN) {
      ctx.addIssue({
        code: "custom",
        path: ["HF_TOKEN"],
        message: "HF_TOKEN wajib diisi kalau LLM_PROVIDER=huggingface",
      });
    }
  });

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error("Invalid environment variables:");
  console.error(z.prettifyError(parsedEnv.error));

  process.exit(1);
}

export const env = parsedEnv.data;
