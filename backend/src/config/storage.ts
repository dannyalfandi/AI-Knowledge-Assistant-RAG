import path from "node:path";

export const storageConfig = {
  documentsPath: path.resolve(process.cwd(), "storage", "documents"),
};
