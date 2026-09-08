import crypto from "node:crypto";
import path from "node:path";

import multer from "multer";

import { storageConfig } from "../config/storage.js";
import { ensureStorageDirectory } from "../services/storage/local-storage.service.js";

const allowedMimeTypes = new Set([
  "application/pdf",
  "application/x-pdf",
  "application/octet-stream",
]);

const allowedExtensions = new Set([".pdf"]);

const storage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    ensureStorageDirectory()
      .then(() => callback(null, storageConfig.documentsPath))
      .catch((error) => callback(error as Error, storageConfig.documentsPath));
  },

  filename: (_req, file, callback) => {
    const extension = path.extname(file.originalname).toLowerCase();

    const storedName = `${crypto.randomUUID()}${extension}`;

    callback(null, storedName);
  },
});

export const uploadDocument = multer({
  storage,

  limits: {
    fileSize: 10 * 1024 * 1024,
  },

  fileFilter: (_req, file, callback) => {
    const extension = path.extname(file.originalname).toLowerCase();

    if (!allowedExtensions.has(extension)) {
      return callback(new Error("Unsupported file extension"));
    }

    if (!allowedMimeTypes.has(file.mimetype)) {
      return callback(new Error("Unsupported file type"));
    }

    callback(null, true);
  },
});
