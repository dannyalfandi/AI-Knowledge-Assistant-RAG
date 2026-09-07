import type { NextFunction, Request, Response } from "express";
import { MulterError } from "multer";
import { ZodError } from "zod";

import { AppError } from "../utils/errors.js";

export function notFoundHandler(_req: Request, res: Response) {
  return res.status(404).json({
    message: "Not found",
  });
}

export function errorHandler(
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
) {
  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      message: error.message,
      ...(error.details === undefined ? {} : { errors: error.details }),
    });
  }

  if (error instanceof ZodError) {
    return res.status(400).json({
      message: "Invalid request",
      errors: error.flatten(),
    });
  }

  if (error instanceof MulterError) {
    const status = error.code === "LIMIT_FILE_SIZE" ? 413 : 400;

    return res.status(status).json({
      message: error.message,
    });
  }

  if (
    error instanceof Error &&
    (error.message === "Unsupported file extension" ||
      error.message === "Unsupported file type")
  ) {
    return res.status(400).json({
      message: error.message,
    });
  }

  console.error("Unhandled error:", error);

  return res.status(500).json({
    message: "Internal server error",
  });
}
