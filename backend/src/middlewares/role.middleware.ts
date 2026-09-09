import type { NextFunction, Request, Response } from "express";

import { ForbiddenError, UnauthorizedError } from "../utils/errors.js";

import type { AuthenticatedRequest } from "./auth.middleware.js";

export function authorize(...allowedRoles: string[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    const authenticatedRequest = req as AuthenticatedRequest;

    if (!authenticatedRequest.user) {
      throw new UnauthorizedError();
    }

    if (!allowedRoles.includes(authenticatedRequest.user.role)) {
      throw new ForbiddenError();
    }

    next();
  };
}
