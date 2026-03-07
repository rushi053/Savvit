/**
 * Product routes — search and lookup.
 * These are PUBLIC (no auth required) for frictionless onboarding.
 */

import { Hono } from "hono";
import { searchPricesAndDeals, searchLaunchIntel } from "../services/perplexity.js";
import { getAmazonPriceHistory } from "../services/keepa.js";
import { generateVerdict, VerdictInput } from "../services/gemini.js";
import { getNextSaleEvent } from "../data/sale-calendar.js";
import { findProductCycle } from "../data/product-cycles.js";
import { getRegionConfig, getSupportedRegions } from "../data/region-config.js";
import { getCached, setCache, CACHE_TTL } from "../utils/cache.js";
import { factCheckLaunchIntel } from "../services/fact-check.js";
import { detectProductCategory } from "../data/sale-calendar.js";
import { checkRateLimit, RATE_LIMITS } from "../utils/rate-limit.js";

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
  const amazonMatch = finalUrl.match(/amazon\.\w+(?:\.\w+)?\/([^/]+)\/dp\/([A-Z0-9]{10})/i);
  if (amazonMatch) {
    const slug = amazonMatch[1]
      .replace(/-/g, " ")
      .replace(/\b\w/g, (c) => c) // keep original case
      .trim();
    const asin = amazonMatch[2];
    // Include ASIN so Perplexity can identify the exact product
    if (slug.length > 5 && slug !== "/" && !slug.includes("amazon")) {
      extracted = `${slug} (Amazon ASIN ${asin})`;
    } else {
      // Slug is useless (just "dp" or too short) — use ASIN only
      extracted = `Amazon ASIN ${asin}`;
    }
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
 * Filter out expired deals based on validUntil date.
 * Removes deals whose expiry date has passed.
 */
function filterExpiredDeals(deals: Array<{ validUntil?: string | null; [key: string]: any }>): typeof deals {
  const now = new Date();
  return deals.filter((deal) => {
    if (!deal.validUntil) return true; // No expiry = keep it
    try {
      const expiry = new Date(deal.validUntil);
      // If the date is valid and in the past, filter it out
      if (!isNaN(expiry.getTime()) && expiry < now) {
        console.log(`[deals] Filtered expired deal: "${deal.title}" (expired ${deal.validUntil})`);
        return false;
      }
    } catch {
      // Can't parse date — keep the deal
    }
    return true;
  });
}

/**
 * Filter deals that reference past sale events (e.g. "Republic Day Sale" in March).
 */
function filterStaleSaleDeals(deals: Array<{ title?: string; description?: string; [key: string]: any }>): typeof deals {
  const now = new Date();
  const currentMonth = now.getMonth() + 1; // 1-12
  
  // Sale events and their typical months
  const pastSalePatterns: Array<{ pattern: RegExp; months: number[] }> = [
    { pattern: /republic day/i, months: [1] },
    { pattern: /new year/i, months: [12, 1] },
    { pattern: /diwali|deepavali/i, months: [10, 11] },
    { pattern: /big billion/i, months: [9, 10] },
    { pattern: /great indian (festival|sale)/i, months: [9, 10] },
    { pattern: /black friday|cyber monday/i, months: [11] },
    { pattern: /prime day/i, months: [7] },
    { pattern: /boxing day/i, months: [12] },
    { pattern: /holiday sale/i, months: [12] },
    { pattern: /valentine/i, months: [2] },
  ];

  return deals.filter((deal) => {
    const text = `${deal.title || ""} ${deal.description || ""}`;
    for (const { pattern, months } of pastSalePatterns) {
      if (pattern.test(text)) {
        // If the sale's typical month(s) have passed, filter it out
        const allMonthsPassed = months.every((m) => m < currentMonth);
        if (allMonthsPassed) {
          console.log(`[deals] Filtered stale sale deal: "${deal.title}" (sale months: ${months}, current: ${currentMonth})`);
          return false;
        }
      }
    }
    return true;
  });
}

/**
 * Detect price outliers — flag prices that are suspiciously far from the median.
 * Returns the same array with `priceConfidence` added to each entry.
 */
function flagPriceOutliers(prices: Array<{ price: number; retailer: string; [key: string]: any }>): typeof prices {
  const validPrices = prices.filter((p) => p.price > 0).map((p) => p.price);
  if (validPrices.length < 2) {
    return prices.map((p) => ({ ...p, priceConfidence: p.price > 0 ? "confirmed" : "unavailable" }));
  }

  // Calculate median
  const sorted = [...validPrices].sort((a, b) => a - b);
  const median = sorted.length % 2 === 0
    ? (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2
    : sorted[Math.floor(sorted.length / 2)];

  return prices.map((p) => {
    if (p.price <= 0) return { ...p, priceConfidence: "unavailable" };
    const deviation = Math.abs(p.price - median) / median;
    if (deviation > 0.5) {
      console.log(`[price-check] Outlier: ${p.retailer} ${p.price} is ${(deviation * 100).toFixed(0)}% from median ${median}`);
      return { ...p, priceConfidence: "suspicious" };
    }
    if (deviation > 0.25) return { ...p, priceConfidence: "estimated" };
    return { ...p, priceConfidence: "confirmed" };
  });
}

/**
 * POST /v1/products/search
 * The main endpoint — search for a product and get the full verdict.
 * This is the magic endpoint that powers the app.
 */
productRoutes.post("/search", async (c) => {
  const startTime = Date.now();
  const { query, region, sourceUrl } = await c.req.json<{ query: string; region?: string; sourceUrl?: string }>();

  if (!query || typeof query !== "string" || query.trim().length < 2) {
    return c.json({ error: "Query must be at least 2 characters" }, 400);
  }

  // Rate limiting (by IP)
  const clientIp = c.req.header("x-forwarded-for")?.split(",")[0]?.trim() || "unknown";
  const userId = c.req.header("authorization") ? "auth" : "anon";
  const rateKey = `search:${clientIp}:${userId}`;
  const rateConfig = userId === "auth" ? RATE_LIMITS.AUTHENTICATED : RATE_LIMITS.ANONYMOUS;
  const rateResult = checkRateLimit(rateKey, rateConfig);
  
  if (!rateResult.allowed) {
    return c.json({
      error: "Too many searches. Please try again later.",
      code: "RATE_LIMITED",
      retryAfterMs: rateResult.retryAfterMs,
      retryAfterSeconds: Math.ceil(rateResult.retryAfterMs / 1000),
    }, 429);
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

  // Check full response cache first (saves ALL API calls on repeat queries)
  const fullCacheKey = `full:${regionConfig.code}:${trimmedQuery.toLowerCase()}`;
  const cachedResponse = getCached<any>(fullCacheKey);
  if (cachedResponse) {
    return c.json({
      ...cachedResponse,
      _meta: { ...cachedResponse._meta, cached: true, latencyMs: Date.now() - startTime },
    });
  }

  try {
    // Step 1+2: Run combined price+deals search AND launch intel in PARALLEL
    // Combined call saves ~3-4s vs separate price + deals calls
    const productCycle = findProductCycle(trimmedQuery);
    const [combinedResult, launchIntel] = await Promise.all([
      // Prices + Deals (single Perplexity call)
      searchPricesAndDeals(trimmedQuery, regionConfig.code, sourceUrl),
      // Launch intel (separate — different prompt structure)
      searchLaunchIntel(trimmedQuery, productCycle?.productLine || "general").catch(() => null),
    ]);
    const priceSearch = combinedResult.priceSearch;
    const dealsResult = combinedResult.dealsResult;

    // Step 2c: Fact-check launch intel
    let launchFactCheck = null;
    if (launchIntel) {
      launchFactCheck = factCheckLaunchIntel(launchIntel, trimmedQuery);
      if (launchFactCheck.warnings.length > 0) {
        console.log(`[fact-check] ${trimmedQuery}: ${launchFactCheck.warnings.join("; ")}`);
      }
      // Apply adjusted confidence back to launch intel
      launchIntel.confidence = launchFactCheck.adjustedConfidence;
      launchIntel.summary = launchFactCheck.cleanedSummary;
      // If unverified and low confidence, null out the upcoming product to avoid misleading users
      if (!launchFactCheck.verified && launchFactCheck.adjustedConfidence < 0.3) {
        console.log(`[fact-check] Suppressing unverified launch intel for "${trimmedQuery}" (confidence: ${launchFactCheck.adjustedConfidence})`);
        launchIntel.upcomingProduct = null;
        launchIntel.expectedDate = null;
        launchIntel.summary = "No reliable information about upcoming product launches found.";
      }
    }

    // Step 3: Get Amazon price history (Keepa) — if we can find an ASIN
    // For MVP, we skip Keepa if no key configured
    // TODO: Extract ASIN from Amazon URL or Keepa search
    const keepaHistory = null; // Will wire up when Keepa key is available

    // Step 4: Get next sale event (region + category aware)
    const currentMonth = new Date().getMonth() + 1;
    const nextSale = getNextSaleEvent(currentMonth, regionConfig.code, trimmedQuery);

    // Step 4b: Filter expired and stale deals
    let filteredDeals = dealsResult.deals || [];
    filteredDeals = filterExpiredDeals(filteredDeals);
    filteredDeals = filterStaleSaleDeals(filteredDeals);

    // Step 4c: Flag price outliers
    priceSearch.prices = flagPriceOutliers(priceSearch.prices);

    // Step 5: Calculate days until next sale (for smarter verdict)
    let daysUntilNextSale: number | null = null;
    if (nextSale) {
      const now = new Date();
      const saleDate = new Date(now.getFullYear(), nextSale.typicalMonth - 1, 15); // mid-month estimate
      if (saleDate < now) {
        saleDate.setFullYear(saleDate.getFullYear() + 1);
      }
      daysUntilNextSale = Math.round((saleDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    }

    // Step 6: Generate verdict (Gemini)
    const noRetailersAvailable = priceSearch.prices.length === 0;
    const verdictInput: VerdictInput = {
      productName: priceSearch.productName || trimmedQuery,
      currentPrices: priceSearch.prices.map((p) => ({
        retailer: p.retailer,
        price: p.price,
        offers: p.offers,
      })),
      notAvailable: noRetailersAvailable,
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
            daysAway: daysUntilNextSale,
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
      deals: filteredDeals.length > 0
        ? filteredDeals.map((d) => ({
            type: d.type,
            title: d.title,
            discount: d.discount,
            retailer: d.retailer,
            code: d.code,
          }))
        : undefined,
    };

    const verdict = await generateVerdict(verdictInput);

    // Assemble final response
    const response = {
      query: trimmedQuery,
      product: priceSearch.productName,
      productImage: priceSearch.productImage || null,
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
            verified: launchFactCheck?.verified ?? false,
            citationQuality: launchFactCheck?.citationQuality ?? "none",
          }
        : null,
      nextSale: nextSale
        ? { name: nextSale.name, month: nextSale.typicalMonth, discount: nextSale.avgDiscount, daysAway: daysUntilNextSale }
        : null,
      priceHistory: keepaHistory
        ? {
            allTimeLow: keepaHistory.allTimeLow,
            allTimeHigh: keepaHistory.allTimeHigh,
            avg90d: keepaHistory.avg90d,
          }
        : null,
      deals: filteredDeals.length > 0
        ? filteredDeals
        : null,
      dealsSummary: filteredDeals.length > 0 ? dealsResult.summary : null,
      citations: [
        ...(priceSearch.citations || []),
        ...(launchIntel?.citations || []),
        ...(dealsResult.citations || []),
      ],
      region: {
        code: regionConfig.code,
        currency: regionConfig.currency,
        currencySymbol: regionConfig.currencySymbol,
      },
      productCategory: detectProductCategory(trimmedQuery),
      _meta: {
        latencyMs: Date.now() - startTime,
        cached: false,
        retailersChecked: priceSearch.prices.length,
        dealsFound: filteredDeals.length,
        rateLimit: { remaining: rateResult.remaining },
      },
    };

    // Cache the full response for 1 hour
    setCache(fullCacheKey, response, 60 * 60 * 1000);

    return c.json(response);
  } catch (err: any) {
    console.error(`[products/search] Error for "${trimmedQuery}":`, err.message);
    
    const message = err.message || "Something went wrong";
    let code = "SEARCH_FAILED";
    let status = 500;
    let suggestion = "Please try again in a moment.";
    
    if (message.includes("API error: 429") || message.includes("rate")) {
      code = "UPSTREAM_RATE_LIMITED";
      status = 503;
      suggestion = "Our data providers are busy. Please try again in 30 seconds.";
    } else if (message.includes("timeout") || message.includes("ETIMEDOUT") || message.includes("ECONNRESET")) {
      code = "TIMEOUT";
      status = 504;
      suggestion = "The search took too long. Try a more specific query (e.g., 'iPhone 16 Pro 256GB' instead of 'iPhone').";
    } else if (message.includes("Could not parse")) {
      code = "PARSE_ERROR";
      suggestion = "We got unexpected data. Try rephrasing your search.";
    } else if (message.includes("Could not determine product")) {
      code = "URL_RESOLVE_FAILED";
      status = 400;
      suggestion = "We couldn't identify the product from that URL. Try entering the product name instead.";
    }
    
    return c.json({ error: message, code, suggestion }, status);
  }
});

/**
 * POST /v1/products/warm
 * Pre-warm cache for popular product searches.
 * Called by cron job to ensure popular searches are instant.
 */
productRoutes.post("/warm", async (c) => {
  const authHeader = c.req.header("authorization");
  const expectedToken = process.env.ADMIN_TOKEN || process.env.RENDER_EXTERNAL_URL;
  if (!authHeader || !authHeader.includes(expectedToken || "__no_admin_token__")) {
    return c.json({ error: "Unauthorized" }, 401);
  }

  const POPULAR_PRODUCTS_IN = [
    "iPhone 16 Pro", "iPhone 16", "MacBook Air M4", "MacBook Pro M4",
    "Samsung Galaxy S25 Ultra", "Samsung Galaxy S25", "PS5", "PS5 Pro",
    "iPad Air M3", "AirPods Pro 3", "Apple Watch Ultra 3",
    "OnePlus 13", "Google Pixel 9 Pro", "Sony WH-1000XM5",
    "Samsung Galaxy Z Fold 6", "Nothing Phone 3",
  ];

  const POPULAR_PRODUCTS_US = [
    "iPhone 16 Pro", "MacBook Air M4", "PS5 Pro", "Samsung Galaxy S25 Ultra",
    "AirPods Pro 3", "Sony WH-1000XM5", "iPad Pro M4", "Nintendo Switch 2",
    "Apple Watch Ultra 3", "Dell XPS 16",
  ];

  const results: Array<{ query: string; region: string; status: string; latencyMs: number }> = [];

  // Warm IN products
  for (const query of POPULAR_PRODUCTS_IN) {
    const start = Date.now();
    try {
      await searchPricesAndDeals(query, "IN");
      results.push({ query, region: "IN", status: "ok", latencyMs: Date.now() - start });
    } catch (err: any) {
      results.push({ query, region: "IN", status: `error: ${err.message}`, latencyMs: Date.now() - start });
    }
  }

  // Warm US products
  for (const query of POPULAR_PRODUCTS_US) {
    const start = Date.now();
    try {
      await searchPricesAndDeals(query, "US");
      results.push({ query, region: "US", status: "ok", latencyMs: Date.now() - start });
    } catch (err: any) {
      results.push({ query, region: "US", status: `error: ${err.message}`, latencyMs: Date.now() - start });
    }
  }

  const okCount = results.filter((r) => r.status === "ok").length;
  return c.json({
    warmed: okCount,
    total: results.length,
    results,
  });
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
