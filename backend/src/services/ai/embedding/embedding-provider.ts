export type EmbeddingInputType = "query" | "passage";

export interface EmbeddingProvider {
  readonly provider: string;
  readonly model: string;
  readonly dimensions: number;

  generateEmbedding(
    text: string,
    inputType?: EmbeddingInputType,
  ): Promise<number[]>;
}
