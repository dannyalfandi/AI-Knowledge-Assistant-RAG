import type { NextFunction, Request, Response } from "express";
import type { ZodType } from "zod";

import { ValidationError } from "../utils/errors.js";

type ValidationSource = "body" | "params" | "query";

export function validate(schema: ZodType, source: ValidationSource = "body") {
  return (req: Request, _res: Response, next: NextFunction) => {
    const result = schema.safeParse(req[source]);

    if (!result.success) {
      throw new ValidationError("Invalid request", result.error.flatten());
    }

    if (source === "query") {
      // Express 5 exposes req.query as a getter that re-parses the URL on every
      // access (no setter, no caching), so replace it with the parsed
      // (coerced + defaulted) result as a plain own property.
      Object.defineProperty(req, "query", {
        value: result.data,
        writable: true,
        configurable: true,
        enumerable: true,
      });
    } else {
      req[source] = result.data;
    }

    next();
  };
}
