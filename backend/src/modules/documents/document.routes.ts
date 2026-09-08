import { Router } from "express";

import { authenticate } from "../../middlewares/auth.middleware.js";
import { uploadDocument } from "../../middlewares/upload.middleware.js";
import { authorize } from "../../middlewares/role.middleware.js";

import {
  deleteDocumentController,
  getDocumentController,
  listDocumentsController,
  processDocumentController,
  uploadDocumentController,
} from "./document.controller.js";

const router = Router();

router.get("/", authenticate, authorize("ADMIN"), listDocumentsController);

router.get("/:id", authenticate, authorize("ADMIN"), getDocumentController);

router.post(
  "/:id/process",
  authenticate,
  authorize("ADMIN"),
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
  deleteDocumentController,
);

export default router;
