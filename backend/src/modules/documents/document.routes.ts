import { Router } from "express";

import { authenticate } from "../../middlewares/auth.middleware.js";
import { uploadDocument } from "../../middlewares/upload.middleware.js";
import { authorize } from "../../middlewares/role.middleware.js";
import { validate } from "../../middlewares/validate.middleware.js";

import {
  deleteDocumentController,
  getDocumentController,
  listDocumentsController,
  processDocumentController,
  uploadDocumentController,
} from "./document.controller.js";
import { documentIdSchema } from "./document.validation.js";

const router = Router();

router.get("/", authenticate, authorize("ADMIN"), listDocumentsController);

router.get(
  "/:id",
  authenticate,
  authorize("ADMIN"),
  validate(documentIdSchema, "params"),
  getDocumentController,
);

router.post(
  "/:id/process",
  authenticate,
  authorize("ADMIN"),
  validate(documentIdSchema, "params"),
  processDocumentController,
);

router.post(
  "/",
  authenticate,
  authorize("ADMIN"),
  uploadDocument.single("file"),
  uploadDocumentController,
);

router.delete(
  "/:id",
  authenticate,
  authorize("ADMIN"),
  validate(documentIdSchema, "params"),
  deleteDocumentController,
);

export default router;
