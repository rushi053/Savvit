/**
 * Keepa API — Amazon price history.
 * Provides years of historical data for Amazon India products.
 * API docs: https://keepa.com/#!discuss/t/using-the-keepa-api/47
 */

import { getCached, setCache, CACHE_TTL } from "../utils/cache.js";

const KEEPA_API_KEY = process.env.KEEPA_API_KEY || "";
const KEEPA_BASE = "https://api.keepa.com";

// Keepa domain codes
const AMAZON_IN = 10; // Amazon India

export interface PriceHistoryPoint {
  date: string;
  price: number; // in INR
}

export interface KeepaResult {
  asin: string;
  title: string;
  currentPrice: number;
  allTimeLow: number;
  allTimeHigh: number;
  avg30d: number;
  avg90d: number;
  avg180d: number;
  priceHistory: PriceHistoryPoint[];
  lastUpdated: string;
}

/**
 * Look up an ASIN on Amazon India via Keepa.
 * Returns full price history.
 */
export async function getAmazonPriceHistory(asin: string): Promise<KeepaResult | null> {
  if (!KEEPA_API_KEY) {
    console.warn("[Keepa] No API key configured — skipping price history");
    return null;
  }

  const cacheKey = `keepa:${asin}`;
  const cached = getCached<KeepaResult>(cacheKey);
  if (cached) return cached;

  try {
    const url = `${KEEPA_BASE}/product?key=${KEEPA_API_KEY}&domain=${AMAZON_IN}&asin=${asin}&history=1&stats=180`;

    const response = await fetch(url);
    if (!response.ok) {
      console.error(`[Keepa] API error: ${response.status}`);
      return null;
    }

    const data = await response.json();
    const product = data.products?.[0];
    if (!product) return null;

    // Keepa stores prices in cents (multiply by 0.01 for INR)
    // Price type 1 = Amazon price, type 0 = Amazon marketplace
    const amazonPrices: number[] = product.csv?.[1] || []; // type 1 = Amazon
    const stats = product.stats || {};

    // Parse price history (Keepa format: [time, price, time, price, ...])
    const history: PriceHistoryPoint[] = [];
    for (let i = 0; i < amazonPrices.length - 1; i += 2) {
      const keepaMinutes = amazonPrices[i];
      const priceRaw = amazonPrices[i + 1];
      if (priceRaw > 0) {
        // Keepa time: minutes since 2011-01-01
        const date = new Date((keepaMinutes + 21564000) * 60000);
        history.push({
          date: date.toISOString().split("T")[0],
          price: priceRaw / 100, // Convert from Keepa cents to INR
        });
      }
    }

    const result: KeepaResult = {
      asin,
      title: product.title || "",
      currentPrice: (stats.current?.[1] || 0) / 100,
      allTimeLow: (stats.min?.[1] || 0) / 100,
      allTimeHigh: (stats.max?.[1] || 0) / 100,
      avg30d: (stats.avg30?.[1] || 0) / 100,
      avg90d: (stats.avg90?.[1] || 0) / 100,
      avg180d: (stats.avg180?.[1] || 0) / 100,
      priceHistory: history,
      lastUpdated: new Date().toISOString(),
    };

    setCache(cacheKey, result, CACHE_TTL.KEEPA_HISTORY);
    return result;
  } catch (err) {
    console.error("[Keepa] Error:", err);
    return null;
  }
}

/**
 * Search for a product on Amazon India via Keepa.
 * Returns matching ASINs.
 */
export async function searchAmazonProduct(query: string): Promise<string[]> {
  if (!KEEPA_API_KEY) return [];

  try {
    const url = `${KEEPA_BASE}/search?key=${KEEPA_API_KEY}&domain=${AMAZON_IN}&type=product&term=${encodeURIComponent(query)}`;

    const response = await fetch(url);
    if (!response.ok) return [];

    const data = await response.json();
    return data.asinList || [];
  } catch {
    return [];
  }
}
