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
import { getRegionConfig, getSupportedRegions } from "../data/region-config.js";

export const productRoutes = new Hono();

/**
 * Detect if a string is a URL (http/https or common shorteners).
 */
function isUrl(s: string): boolean {
  return /^https?:\/\//i.test(s) || /^(amzn\.in|bit\.ly|tinyurl\.com|fkrt\.it)\//i.test(s);
}

/**
 * Resolve a product URL to a product name.
 * Strategy:
 * 1. Follow redirects to get the final URL
 * 2. Extract product name from URL slug (Amazon, Flipkart patterns)
 * 3. Fallback: use Perplexity to identify (unreliable — sometimes refuses)
 */
async function resolveProductUrl(url: string): Promise<string> {
  if (!/^https?:\/\//i.test(url)) url = "https://" + url;

  // Step 1: Follow redirects to get final URL
  let finalUrl = url;
  try {
    const resp = await fetch(url, {
      method: "HEAD",
      redirect: "follow",
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
      },
    });
    finalUrl = resp.url;
  } catch {
    // If HEAD fails, try GET
    try {
      const resp = await fetch(url, {
        redirect: "follow",
        headers: {
          "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
          "Accept-Encoding": "identity",
        },
      });
      finalUrl = resp.url;
    } catch {
      // Can't resolve — fall through to Perplexity
    }
  }

  console.log(`[URL resolve] redirect: ${url} → ${finalUrl}`);

  // Step 2: Extract product name from URL patterns
  let extracted: string | null = null;

  // Amazon: /Product-Name-Here/dp/ASIN
  const amazonMatch = finalUrl.match(/amazon\.\w+(?:\.\w+)?\/([^/]+)\/dp\//i);
  if (amazonMatch) {
    extracted = amazonMatch[1]
      .replace(/-/g, " ")
      .replace(/\b\w/g, (c) => c) // keep original case
      .trim();
  }

  // Flipkart: /product-name/p/itm...
  if (!extracted) {
    const flipkartMatch = finalUrl.match(/flipkart\.com\/([^/]+)\/p\//i);
    if (flipkartMatch) {
      extracted = flipkartMatch[1].replace(/-/g, " ").trim();
    }
  }

  // Croma: /product-name/p/...
  if (!extracted) {
    const cromaMatch = finalUrl.match(/croma\.com\/([^/]+)\/p\//i);
    if (cromaMatch) {
      extracted = cromaMatch[1].replace(/-/g, " ").trim();
    }
  }

  // Best Buy: /site/product-name/skuId.p
  if (!extracted) {
    const bestbuyMatch = finalUrl.match(/bestbuy\.com?\/site\/([^/]+)\/\d+\.p/i);
    if (bestbuyMatch) {
      extracted = bestbuyMatch[1].replace(/-/g, " ").trim();
    }
  }

  // Walmart: /ip/product-name/itemId
  if (!extracted) {
    const walmartMatch = finalUrl.match(/walmart\.com?\/ip\/([^/]+)\//i);
    if (walmartMatch) {
      extracted = walmartMatch[1].replace(/-/g, " ").trim();
    }
  }

  // Target: /p/product-name/-/A-itemId
  if (!extracted) {
    const targetMatch = finalUrl.match(/target\.com\/p\/([^/]+)\/-\//i);
    if (targetMatch) {
      extracted = targetMatch[1].replace(/-/g, " ").trim();
    }
  }

  // JB Hi-Fi: /products/category/product-name
  if (!extracted) {
    const jbMatch = finalUrl.match(/jbhifi\.com\.au\/products\/[^/]+\/([^?]+)/i);
    if (jbMatch) {
      extracted = jbMatch[1].replace(/-/g, " ").trim();
    }
  }

  if (extracted && extracted.length > 3) {
    console.log(`[URL resolve] extracted from URL: "${extracted}"`);
    return extracted;
  }

  // Step 3: Fallback — ask Perplexity (may or may not work)
  const PERPLEXITY_API_KEY = process.env.PERPLEXITY_API_KEY || "";
  try {
    const response = await fetch("https://api.perplexity.ai/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${PERPLEXITY_API_KEY}`,
      },
      body: JSON.stringify({
        model: "sonar",
        messages: [
          {
            role: "system",
            content: `You are a product identifier. Given a product URL, return ONLY the exact product name. Nothing else — no explanation, no markdown, no quotes.`,
          },
          { role: "user", content: `What product is this? ${finalUrl}` },
        ],
        temperature: 0.1,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      const name = data.choices?.[0]?.message?.content?.trim();
      if (name && name.length > 3 && name.length < 200 && !name.includes("don't have") && !name.includes("cannot")) {
        console.log(`[URL resolve] Perplexity: "${name}"`);
        return name;
      }
    }
  } catch {
    // Perplexity failed — last resort below
  }

  throw new Error("Could not determine product name from URL. Please enter the product name instead.");
}

/**
 * POST /v1/products/search
 * The main endpoint — search for a product and get the full verdict.
 * This is the magic endpoint that powers the app.
 */
productRoutes.post("/search", async (c) => {
  const startTime = Date.now();
  const { query, region } = await c.req.json<{ query: string; region?: string }>();

  if (!query || typeof query !== "string" || query.trim().length < 2) {
    return c.json({ error: "Query must be at least 2 characters" }, 400);
  }

  const regionConfig = getRegionConfig(region);

  let trimmedQuery = query.trim();

  // If query is a URL, resolve it to a product name first
  if (isUrl(trimmedQuery)) {
    try {
      trimmedQuery = await resolveProductUrl(trimmedQuery);
    } catch (err: any) {
      return c.json({ error: err.message, code: "URL_RESOLVE_FAILED" }, 400);
    }
  }

  try {
    // Step 1: Get current prices across retailers (Perplexity, region-aware)
    const priceSearch = await searchPrices(trimmedQuery, regionConfig.code);

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

    // Step 4: Get next sale event (region-aware)
    const currentMonth = new Date().getMonth() + 1;
    const nextSale = getNextSaleEvent(currentMonth, regionConfig.code);

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
      region: regionConfig.code,
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
      region: {
        code: regionConfig.code,
        currency: regionConfig.currency,
        currencySymbol: regionConfig.currencySymbol,
      },
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
  const region = c.req.query("region");
  const currentMonth = new Date().getMonth() + 1;
  const nextSale = getNextSaleEvent(currentMonth, region);
  return c.json({ currentMonth, region: region || "US", nextSale });
});

/**
 * GET /v1/products/regions
 * Returns list of supported regions.
 */
productRoutes.get("/regions", (c) => {
  const regions = getSupportedRegions().map((code) => {
    const rc = getRegionConfig(code);
    return { code: rc.code, name: rc.name, currency: rc.currency, currencySymbol: rc.currencySymbol };
  });
  return c.json({ regions });
});
