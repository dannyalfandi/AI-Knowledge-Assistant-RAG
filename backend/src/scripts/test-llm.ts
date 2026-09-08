import "dotenv/config";

import type { LlmMessage } from "../services/ai/llm/llm-provider.js";
import { getLlmProvider } from "../services/ai/llm/llm.service.js";

/**
 * Manual connectivity check for the configured LLM provider (TAHAP 1).
 *
 * Not wired to the RAG pipeline yet — this only proves the provider can reach
 * its API and return a sensible answer.
 *
 *   npm run test:llm
 *   npm run test:llm -- "berapa lama batas pengajuan refund?"
 */
async function main() {
  const provider = getLlmProvider();

  const question =
    process.argv.slice(2).join(" ").trim() ||
    "Jelaskan dalam satu kalimat apa itu Retrieval Augmented Generation.";

  const messages: LlmMessage[] = [
    {
      role: "system",
      content: "Kamu asisten yang ringkas. Jawab maksimal dua kalimat.",
    },
    { role: "user", content: question },
  ];

  console.log("Provider:", provider.provider);
  console.log("Model:   ", provider.model);
  console.log("Question:", question);
  console.log("---");

  const startedAt = Date.now();
  const result = await provider.generateCompletion(messages);
  const elapsedMs = Date.now() - startedAt;

  console.log("Answer:", result.content);
  console.log("---");
  console.log("finishReason:", result.finishReason);
  console.log("usage:", result.usage);
  console.log(`elapsed: ${elapsedMs}ms`);
}

main().catch((error) => {
  console.error("LLM test failed:");
  console.error(error);
  process.exitCode = 1;
});
