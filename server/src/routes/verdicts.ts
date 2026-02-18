/**
 * Verdict routes — get/refresh verdicts for products.
 * Protected by auth middleware.
 */

import { Hono } from "hono";
import { supabaseAdmin } from "../utils/auth.js";

export const verdictRoutes = new Hono();

/**
 * GET /v1/verdicts/:watchlistId
 * Get the full verdict for a watchlist item.
 * Returns the latest cached verdict, including pro analysis.
 */
verdictRoutes.get("/:watchlistId", async (c) => {
  const userId = c.get("userId");
  const watchlistId = c.req.param("watchlistId");

  // Verify ownership
  const { data: item, error: itemErr } = await supabaseAdmin
    .from("watchlist")
    .select("id, product_name, query")
    .eq("id", watchlistId)
    .eq("user_id", userId)
    .single();

  if (itemErr || !item) {
    return c.json({ error: "Watchlist item not found" }, 404);
  }

  // Get latest verdict
  const { data: verdict, error: verdictErr } = await supabaseAdmin
    .from("verdicts")
    .select("*")
    .eq("watchlist_id", watchlistId)
    .order("generated_at", { ascending: false })
    .limit(1)
    .single();

  if (verdictErr || !verdict) {
    return c.json({
      error: "No verdict available yet. Try refreshing.",
      code: "NO_VERDICT",
    }, 404);
  }

  return c.json({
    product: item.product_name,
    verdict: verdict.verdict,
    confidence: verdict.confidence,
    shortReason: verdict.short_reason,
    reason: verdict.reason,
    bestPrice: verdict.best_price,
    bestRetailer: verdict.best_retailer,
    allPrices: verdict.all_prices,
    proAnalysis: verdict.pro_analysis,
    launchIntel: verdict.launch_intel,
    nextSale: verdict.next_sale,
    priceHistory: verdict.price_history,
    citations: verdict.citations,
    generatedAt: verdict.generated_at,
  });
});
