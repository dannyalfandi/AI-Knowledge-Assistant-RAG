import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";

import authRoutes from "./modules/auth/auth.routes.js";
import {
  authenticate,
  type AuthenticatedRequest,
} from "./middlewares/auth.middleware.js";
import documentRoutes from "./modules/documents/document.routes.js";
import searchRoutes from "./modules/search/search.routes.js";
import conversationRoutes from "./modules/conversations/conversation.routes.js";
import feedbackRoutes from "./modules/feedback/feedback.routes.js";
import adminRoutes from "./modules/admin/admin.routes.js";
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

app.use("/api/messages", feedbackRoutes);

app.use("/api/auth", authRoutes);

app.get("/api/auth/me", authenticate, (req: AuthenticatedRequest, res) => {
  return res.status(200).json({
    data: { user: req.user },
  });
});

app.use("/api/admin", adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
