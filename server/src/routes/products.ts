/**
 * Product routes — search and lookup.
 * These are PUBLIC (no auth required) for frictionless onboarding.
 */

import { Hono } from "hono";
import { searchPrices, searchLaunchIntel } from "../services/perplexity.js";
import { getAmazonPriceHistory } from "../services/keepa.js";
import { generateVerdict, VerdictInput } from "../services/gemini.js";
import { getNextSaleEvent } from "../data/sale-calendar.js";
import { findProductCycle } from "../data/product-cycles.js";

export const productRoutes = new Hono();

/**
 * POST /v1/products/search
 * The main endpoint — search for a product and get the full verdict.
 * This is the magic endpoint that powers the app.
 */
productRoutes.post("/search", async (c) => {
  const startTime = Date.now();
  const { query } = await c.req.json<{ query: string }>();

  if (!query || typeof query !== "string" || query.trim().length < 2) {
    return c.json({ error: "Query must be at least 2 characters" }, 400);
  }

  const trimmedQuery = query.trim();

  try {
    // Step 1: Get current prices across retailers (Perplexity)
    const priceSearch = await searchPrices(trimmedQuery);

    // Step 2: Get launch intelligence (Perplexity, cached 7 days)
    const productCycle = findProductCycle(trimmedQuery);
    const launchIntel = await searchLaunchIntel(
      trimmedQuery,
      productCycle?.productLine || "general"
    ).catch(() => null);

    // Step 3: Get Amazon price history (Keepa) — if we can find an ASIN
    // For MVP, we skip Keepa if no key configured
    // TODO: Extract ASIN from Amazon URL or Keepa search
    const keepaHistory = null; // Will wire up when Keepa key is available

    // Step 4: Get next sale event
    const currentMonth = new Date().getMonth() + 1;
    const nextSale = getNextSaleEvent(currentMonth);

    // Step 5: Generate verdict (Gemini)
    const verdictInput: VerdictInput = {
      productName: priceSearch.productName || trimmedQuery,
      currentPrices: priceSearch.prices.map((p) => ({
        retailer: p.retailer,
        price: p.price,
        offers: p.offers,
      })),
      bestPrice: priceSearch.bestPrice
        ? { retailer: priceSearch.bestPrice.retailer, price: priceSearch.bestPrice.price }
        : null,
      priceHistory: keepaHistory
        ? {
            allTimeLow: keepaHistory.allTimeLow,
            allTimeHigh: keepaHistory.allTimeHigh,
            avg90d: keepaHistory.avg90d,
            avg180d: keepaHistory.avg180d,
            currentVsAvg: priceSearch.bestPrice
              ? priceSearch.bestPrice.price < keepaHistory.avg90d
                ? "below"
                : priceSearch.bestPrice.price > keepaHistory.avg90d
                ? "above"
                : "at"
              : "unknown",
          }
        : undefined,
      launchIntel: launchIntel
        ? {
            upcomingProduct: launchIntel.upcomingProduct,
            expectedDate: launchIntel.expectedDate,
            impact: launchIntel.impact,
            confidence: launchIntel.confidence,
          }
        : undefined,
      nextSaleEvent: nextSale
        ? {
            name: nextSale.name,
            date: `${nextSale.typicalMonth}/2026`,
            historicalDiscount: nextSale.avgDiscount,
          }
        : undefined,
      productCycle: productCycle
        ? {
            brand: productCycle.brand,
            typicalLaunchMonth: productCycle.typicalLaunchMonth,
            lastLaunch: "See launch intel",
          }
        : undefined,
    };

    const verdict = await generateVerdict(verdictInput);

    // Assemble final response
    const response = {
      query: trimmedQuery,
      product: priceSearch.productName,
      verdict: verdict.verdict,
      confidence: verdict.confidence,
      shortReason: verdict.shortReason,
      reason: verdict.reason,
      bestPrice: priceSearch.bestPrice,
      prices: priceSearch.prices,
      proAnalysis: verdict.proAnalysis,
      launchIntel: launchIntel
        ? {
            upcomingProduct: launchIntel.upcomingProduct,
            expectedDate: launchIntel.expectedDate,
            summary: launchIntel.summary,
          }
        : null,
      nextSale: nextSale
        ? { name: nextSale.name, month: nextSale.typicalMonth, discount: nextSale.avgDiscount }
        : null,
      priceHistory: keepaHistory
        ? {
            allTimeLow: keepaHistory.allTimeLow,
            allTimeHigh: keepaHistory.allTimeHigh,
            avg90d: keepaHistory.avg90d,
          }
        : null,
      citations: [
        ...(priceSearch.citations || []),
        ...(launchIntel?.citations || []),
      ],
      _meta: {
        latencyMs: Date.now() - startTime,
        cached: false,
      },
    };

    return c.json(response);
  } catch (err: any) {
    console.error(`[products/search] Error for "${trimmedQuery}":`, err.message);
    return c.json({ error: err.message, code: "SEARCH_FAILED" }, 500);
  }
});

/**
 * GET /v1/products/sale-calendar
 * Returns upcoming sale events.
 */
productRoutes.get("/sale-calendar", (c) => {
  const currentMonth = new Date().getMonth() + 1;
  const nextSale = getNextSaleEvent(currentMonth);
  return c.json({ currentMonth, nextSale });
});
