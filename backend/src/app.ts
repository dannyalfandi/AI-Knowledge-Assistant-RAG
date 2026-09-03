import express from "express";
import authRoutes from "./modules/auth/auth.routes.js";
import {
  authenticate,
  type AuthenticatedRequest,
} from "./middlewares/auth.middleware.js";

const app = express();

app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: "backend",
  });
});

app.use("/api/auth", authRoutes);

app.get("/api/auth/me", authenticate, (req: AuthenticatedRequest, res) => {
  return res.status(200).json({
    user: req.user,
  });
});

export default app;
