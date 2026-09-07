import type { NextFunction, Request, Response } from "express";
import { describe, expect, it, vi } from "vitest";
import { z } from "zod";

import { validate } from "../../src/middlewares/validate.middleware.js";
import { ValidationError } from "../../src/utils/errors.js";

const bodySchema = z.object({ name: z.string().min(1) });
const querySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

function runValidate(
  schema: Parameters<typeof validate>[0],
  source: Parameters<typeof validate>[1],
  req: Partial<Request>,
) {
  const next = vi.fn() as unknown as NextFunction;
  validate(schema, source)(req as Request, {} as Response, next);
  return next as unknown as ReturnType<typeof vi.fn>;
}

describe("validate middleware", () => {
  it("replaces req.body with the parsed value", () => {
    const req: Partial<Request> = { body: { name: "Danny", extra: "dropped" } };

    const next = runValidate(bodySchema, "body", req);

    expect(next).toHaveBeenCalledOnce();
    expect(req.body).toEqual({ name: "Danny" });
  });

  it("throws ValidationError on invalid input", () => {
    const req: Partial<Request> = { body: { name: "" } };

    expect(() => runValidate(bodySchema, "body", req)).toThrow(ValidationError);
  });

  it("overrides the Express 5 re-parsing query getter with coerced values", () => {
    // Simulate Express 5: req.query is a getter that re-parses every access.
    const req = {} as Request;
    Object.defineProperty(req, "query", {
      configurable: true,
      enumerable: true,
      get: () => ({ page: "3", limit: "50" }),
    });

    const next = runValidate(querySchema, "query", req);

    expect(next).toHaveBeenCalledOnce();
    expect(req.query).toEqual({ page: 3, limit: 50 });
    // Stable across repeated reads (the getter would otherwise return strings).
    expect(req.query).toBe(req.query);
  });

  it("applies query defaults when params are absent", () => {
    const req = {} as Request;
    Object.defineProperty(req, "query", {
      configurable: true,
      enumerable: true,
      get: () => ({}),
    });

    runValidate(querySchema, "query", req);

    expect(req.query).toEqual({ page: 1, limit: 20 });
  });
});
