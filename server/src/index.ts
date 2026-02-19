import "./env.js";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { productRoutes } from "./routes/products.js";
import { watchlistRoutes } from "./routes/watchlist.js";
import { verdictRoutes } from "./routes/verdicts.js";
import { authMiddleware } from "./utils/auth.js";

const app = new Hono();

// Middleware
app.use("*", logger());
app.use("*", cors());

// Health check
app.get("/health", (c) => {
  return c.json({ status: "ok", service: "savvit-api", version: "1.1.0-global", timestamp: new Date().toISOString() });
});

// Public routes (no auth needed)
app.route("/v1/products", productRoutes);

// Protected routes
app.use("/v1/watchlist/*", authMiddleware);
app.use("/v1/verdicts/*", authMiddleware);
app.route("/v1/watchlist", watchlistRoutes);
app.route("/v1/verdicts", verdictRoutes);

// Error handler
app.onError((err, c) => {
  console.error(`[ERROR] ${err.message}`, err.stack);
  return c.json({ error: err.message, code: "INTERNAL_ERROR" }, 500);
});

import { serve } from "@hono/node-server";

const port = parseInt(process.env.PORT || "3000");

serve({ fetch: app.fetch, port }, () => {
  console.log(`🚀 Savvit API running on port ${port}`);
});
