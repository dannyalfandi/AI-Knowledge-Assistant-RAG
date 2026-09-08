import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";

import authRoutes from "./modules/auth/auth.routes.js";
import {
  authenticate,
  type AuthenticatedRequest,
} from "./middlewares/auth.middleware.js";
import { authorize } from "./middlewares/role.middleware.js";
import documentRoutes from "./modules/documents/document.routes.js";
import searchRoutes from "./modules/search/search.routes.js";
import conversationRoutes from "./modules/conversations/conversation.routes.js";
import {
  errorHandler,
  notFoundHandler,
} from "./middlewares/error.middleware.js";

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan("dev"));
app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: "backend",
  });
});

app.use("/api/documents", documentRoutes);

app.use("/api/search", searchRoutes);

app.use("/api/conversations", conversationRoutes);

app.use("/api/auth", authRoutes);

app.get("/api/auth/me", authenticate, (req: AuthenticatedRequest, res) => {
  return res.status(200).json({
    user: req.user,
  });
});

app.get("/api/admin/test", authenticate, authorize("ADMIN"), (_req, res) => {
  return res.status(200).json({
    message: "You have ADMIN access",
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
