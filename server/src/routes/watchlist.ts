/**
 * Watchlist routes — CRUD for user's tracked products.
 * Protected by auth middleware.
 */

import { Hono } from "hono";
import { supabaseAdmin } from "../utils/auth.js";

export const watchlistRoutes = new Hono();

/**
 * GET /v1/watchlist
 * Get user's watchlist items with latest verdicts.
 */
watchlistRoutes.get("/", async (c) => {
  const userId = c.get("userId");

  const { data, error } = await supabaseAdmin
    .from("watchlist")
    .select(`
      id,
      product_name,
      query,
      source_url,
      target_price,
      notify_on_drop,
      created_at,
      verdicts (
        verdict,
        confidence,
        short_reason,
        best_price,
        best_retailer,
        generated_at
      )
    `)
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  // Flatten: attach latest verdict to each item
  const items = (data || []).map((item: any) => {
    const latestVerdict = item.verdicts?.[0] || null;
    return {
      id: item.id,
      productName: item.product_name,
      query: item.query,
      sourceUrl: item.source_url,
      targetPrice: item.target_price,
      notifyOnDrop: item.notify_on_drop,
      createdAt: item.created_at,
      verdict: latestVerdict
        ? {
            verdict: latestVerdict.verdict,
            confidence: latestVerdict.confidence,
            shortReason: latestVerdict.short_reason,
            bestPrice: latestVerdict.best_price,
            bestRetailer: latestVerdict.best_retailer,
            generatedAt: latestVerdict.generated_at,
          }
        : null,
    };
  });

  return c.json({ items, count: items.length });
});

/**
 * POST /v1/watchlist
 * Add a product to the watchlist.
 */
watchlistRoutes.post("/", async (c) => {
  const userId = c.get("userId");
  const { productName, query, sourceUrl, targetPrice } = await c.req.json();

  if (!productName || !query) {
    return c.json({ error: "productName and query are required" }, 400);
  }

  // Check watchlist limit for free users
  // TODO: Check Pro status via RevenueCat
  const { count } = await supabaseAdmin
    .from("watchlist")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId);

  const FREE_LIMIT = 3;
  if ((count || 0) >= FREE_LIMIT) {
    return c.json({
      error: "Free plan allows 3 items. Upgrade to Pro for unlimited.",
      code: "WATCHLIST_LIMIT",
      limit: FREE_LIMIT,
    }, 403);
  }

  const { data, error } = await supabaseAdmin
    .from("watchlist")
    .insert({
      user_id: userId,
      product_name: productName,
      query,
      source_url: sourceUrl || null,
      target_price: targetPrice || null,
      notify_on_drop: true,
    })
    .select()
    .single();

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  return c.json({ item: data }, 201);
});

/**
 * DELETE /v1/watchlist/:id
 * Remove a product from the watchlist.
 */
watchlistRoutes.delete("/:id", async (c) => {
  const userId = c.get("userId");
  const itemId = c.req.param("id");

  const { error } = await supabaseAdmin
    .from("watchlist")
    .delete()
    .eq("id", itemId)
    .eq("user_id", userId);

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  return c.json({ deleted: true });
});

/**
 * PATCH /v1/watchlist/:id
 * Update target price or notification settings.
 */
watchlistRoutes.patch("/:id", async (c) => {
  const userId = c.get("userId");
  const itemId = c.req.param("id");
  const updates = await c.req.json();

  const allowedFields: Record<string, string> = {
    targetPrice: "target_price",
    notifyOnDrop: "notify_on_drop",
  };

  const dbUpdates: Record<string, any> = {};
  for (const [key, val] of Object.entries(updates)) {
    if (allowedFields[key]) {
      dbUpdates[allowedFields[key]] = val;
    }
  }

  if (Object.keys(dbUpdates).length === 0) {
    return c.json({ error: "No valid fields to update" }, 400);
  }

  const { data, error } = await supabaseAdmin
    .from("watchlist")
    .update(dbUpdates)
    .eq("id", itemId)
    .eq("user_id", userId)
    .select()
    .single();

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  return c.json({ item: data });
});
