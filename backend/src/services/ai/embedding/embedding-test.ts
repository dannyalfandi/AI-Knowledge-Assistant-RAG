import { HuggingFaceEmbeddingProvider } from "./huggingface.provider.js";

async function main() {
  const provider = new HuggingFaceEmbeddingProvider();

  const text =
    "Employees are entitled to 12 days of annual leave per calendar year.";

  console.log("Provider:", provider.provider);
  console.log("Model:", provider.model);
  console.log("Expected dimensions:", provider.dimensions);

  const embedding = await provider.generateEmbedding(text);

  console.log("Received embedding:", Array.isArray(embedding));
  console.log("Dimensions:", embedding.length);
  console.log("First 5 values:", embedding.slice(0, 5));
  console.log(
    "All values are numbers:",
    embedding.every((value) => typeof value === "number"),
  );
  console.log(
    "Contains invalid values:",
    embedding.some((value) => !Number.isFinite(value)),
  );
}

main().catch((error) => {
  console.error("Embedding test failed:");
  console.error(error);
  process.exit(1);
});
