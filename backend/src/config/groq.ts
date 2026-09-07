import OpenAI from "openai";

import { env } from "./env.js";

const GROQ_BASE_URL = "https://api.groq.com/openai/v1";

let client: OpenAI | null = null;

export function getGroqClient(): OpenAI {
  if (!env.GROQ_API_KEY) {
    throw new Error(
      "GROQ_API_KEY is not set but the Groq client was requested",
    );
  }

  if (!client) {
    client = new OpenAI({
      apiKey: env.GROQ_API_KEY,
      baseURL: GROQ_BASE_URL,
    });
  }

  return client;
}
