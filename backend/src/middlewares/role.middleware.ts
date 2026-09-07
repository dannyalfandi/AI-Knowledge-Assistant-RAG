import type { NextFunction, Request, Response } from "express";

import type { AuthenticatedRequest } from "./auth.middleware.js";

export function authorize(...allowedRoles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const authenticatedRequest = req as AuthenticatedRequest;

    if (!authenticatedRequest.user) {
      return res.status(401).json({
        message: "Authentication required",
      });
    }

    if (!allowedRoles.includes(authenticatedRequest.user.role)) {
      return res.status(403).json({
        message: "Forbidden",
      });
    }

    next();
  };
}
