import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middlewares/auth.middleware.js";
import { semanticSearch } from "./search.service.js";
import type { SearchQueryInput } from "./search.validation.js";

export async function searchController(
  req: AuthenticatedRequest,
  res: Response,
) {
  const data = await semanticSearch(req.body as SearchQueryInput);

  return res.status(200).json({ data });
}
