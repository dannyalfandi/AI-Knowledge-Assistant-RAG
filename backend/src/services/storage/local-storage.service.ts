import { mkdir, unlink } from "node:fs/promises";
import path from "node:path";

import { storageConfig } from "../../config/storage.js";

export async function ensureStorageDirectory() {
  await mkdir(storageConfig.documentsPath, {
    recursive: true,
  });
}

export async function deleteStoredFile(filePath: string) {
  try {
    await unlink(filePath);
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;

    if (code !== "ENOENT") {
      throw error;
    }
  }
}

export function getStoredFilePath(storedName: string) {
  return path.join(storageConfig.documentsPath, storedName);
}
