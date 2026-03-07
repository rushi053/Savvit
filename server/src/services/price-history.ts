/**
 * Price History Service
 * Stores every price from product searches and serves historical data.
 * This builds our own price database over time without external APIs.
 */

import { supabaseAdmin } from "../utils/auth.js";

interface PriceInput {
  retailer: string;
  price: number;
  currency: string;
  inStock?: boolean;
  offers?: string;
}

interface PriceHistoryStats {
  currentAvg: number;
  thirtyDayAvg: number;
  ninetyDayAvg: number;
  allTimeHigh: number;
  allTimeLow: number;
  trend: "rising" | "falling" | "stable";
  percentFromLow: number;
  percentFromHigh: number;
}

interface PriceHistoryResult {
  history: Array<{
    date: string;
    prices: Array<{ retailer: string; price: number }>;
  }>;
  stats: PriceHistoryStats;
}

/**
 * Normalize product name for consistent matching.
 * Removes extra spaces, lowercases, trims model suffixes.
 */
function normalizeProductName(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/\s+/g, " ") // collapse multiple spaces
    .replace(/\(.*?\)/g, "") // remove parentheticals
    .replace(/\s+-\s+/g, " ") // normalize dashes
    .trim();
}

/**
 * Store prices from a product search into Supabase.
 * Fire-and-forget — returns immediately, logs errors but doesn't throw.
 * 
 * Deduplication: Don't store the same product+retailer+price if it was stored in the last 6 hours.
 */
export function storePrices(
  productName: string,
  query: string,
  region: string,
  prices: PriceInput[]
): void {
  // Fire-and-forget async operation
  (async () => {
    try {
      const normalizedName = normalizeProductName(productName);
      const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString();

      // Build batch insert array
      const records = [];

      for (const priceEntry of prices) {
        // Skip invalid prices
        if (!priceEntry.price || priceEntry.price <= 0) continue;

        // Check for duplicates in the last 6 hours
        const { data: existing } = await supabaseAdmin
          .from("price_history")
          .select("id")
          .eq("product_name", normalizedName)
          .eq("region", region)
          .eq("retailer", priceEntry.retailer)
          .eq("price", priceEntry.price)
          .gte("created_at", sixHoursAgo)
          .limit(1);

        // Skip if duplicate found
        if (existing && existing.length > 0) {
          console.log(
            `[price-history] Skip duplicate: ${normalizedName} @ ${priceEntry.retailer} = ${priceEntry.price} (last stored <6h ago)`
          );
          continue;
        }

        // Add to batch
        records.push({
          product_name: normalizedName,
          product_query: query,
          region,
          retailer: priceEntry.retailer,
          price: priceEntry.price,
          currency: priceEntry.currency,
          in_stock: priceEntry.inStock ?? true,
          offers: priceEntry.offers || null,
        });
      }

      // Batch insert all non-duplicate records
      if (records.length > 0) {
        const { error } = await supabaseAdmin.from("price_history").insert(records);

        if (error) {
          console.error(`[price-history] Insert error:`, error.message);
        } else {
          console.log(
            `[price-history] Stored ${records.length} prices for "${normalizedName}" (${region})`
          );
        }
      } else {
        console.log(`[price-history] No new prices to store for "${normalizedName}" (all duplicates)`);
      }
    } catch (err: any) {
      console.error(`[price-history] storePrices failed:`, err.message);
    }
  })();
}

/**
 * Get historical price data for a product.
 * Returns daily aggregated history + trend statistics.
 * 
 * @param productName - Product name (will be normalized)
 * @param region - Region code (e.g., 'US', 'IN')
 * @param days - How many days back to fetch (default: 90)
 */
export async function getPriceHistory(
  productName: string,
  region: string,
  days: number = 90
): Promise<PriceHistoryResult | null> {
  try {
    const normalizedName = normalizeProductName(productName);
    const cutoffDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

    // Fetch all price records for this product in the time window
    const { data: records, error } = await supabaseAdmin
      .from("price_history")
      .select("retailer, price, created_at")
      .eq("product_name", normalizedName)
      .eq("region", region)
      .gte("created_at", cutoffDate)
      .order("created_at", { ascending: false });

    if (error) {
      console.error(`[price-history] Query error:`, error.message);
      return null;
    }

    // Not enough data yet
    if (!records || records.length === 0) {
      console.log(`[price-history] No history found for "${normalizedName}" (${region})`);
      return null;
    }

    // Also fetch all-time data for all-time high/low
    const { data: allTimeRecords } = await supabaseAdmin
      .from("price_history")
      .select("price")
      .eq("product_name", normalizedName)
      .eq("region", region);

    const allPrices = (allTimeRecords || []).map((r) => r.price).filter((p) => p > 0);

    // Calculate all-time stats
    const allTimeHigh = allPrices.length > 0 ? Math.max(...allPrices) : 0;
    const allTimeLow = allPrices.length > 0 ? Math.min(...allPrices) : 0;

    // Group by date (YYYY-MM-DD)
    const dailyGroups: Record<string, Array<{ retailer: string; price: number }>> = {};

    for (const rec of records) {
      const date = new Date(rec.created_at).toISOString().split("T")[0]; // YYYY-MM-DD
      if (!dailyGroups[date]) {
        dailyGroups[date] = [];
      }
      dailyGroups[date].push({ retailer: rec.retailer, price: rec.price });
    }

    // Convert to sorted array
    const history = Object.entries(dailyGroups)
      .map(([date, prices]) => ({ date, prices }))
      .sort((a, b) => b.date.localeCompare(a.date)); // newest first

    // Calculate averages for different time windows
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);

    const recentPrices = records.map((r) => r.price).filter((p) => p > 0);
    const thirtyDayPrices = records
      .filter((r) => new Date(r.created_at) >= thirtyDaysAgo)
      .map((r) => r.price)
      .filter((p) => p > 0);
    const ninetyDayPrices = records
      .filter((r) => new Date(r.created_at) >= ninetyDaysAgo)
      .map((r) => r.price)
      .filter((p) => p > 0);

    const currentAvg = recentPrices.length > 0
      ? recentPrices.reduce((sum, p) => sum + p, 0) / recentPrices.length
      : 0;

    const thirtyDayAvg = thirtyDayPrices.length > 0
      ? thirtyDayPrices.reduce((sum, p) => sum + p, 0) / thirtyDayPrices.length
      : currentAvg;

    const ninetyDayAvg = ninetyDayPrices.length > 0
      ? ninetyDayPrices.reduce((sum, p) => sum + p, 0) / ninetyDayPrices.length
      : currentAvg;

    // Calculate trend: compare last 7 days avg vs previous 7 days avg
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const fourteenDaysAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

    const lastSevenDayPrices = records
      .filter((r) => new Date(r.created_at) >= sevenDaysAgo)
      .map((r) => r.price)
      .filter((p) => p > 0);

    const prevSevenDayPrices = records
      .filter((r) => {
        const date = new Date(r.created_at);
        return date >= fourteenDaysAgo && date < sevenDaysAgo;
      })
      .map((r) => r.price)
      .filter((p) => p > 0);

    let trend: "rising" | "falling" | "stable" = "stable";

    if (lastSevenDayPrices.length > 0 && prevSevenDayPrices.length > 0) {
      const lastAvg = lastSevenDayPrices.reduce((sum, p) => sum + p, 0) / lastSevenDayPrices.length;
      const prevAvg = prevSevenDayPrices.reduce((sum, p) => sum + p, 0) / prevSevenDayPrices.length;
      const change = (lastAvg - prevAvg) / prevAvg;

      if (change > 0.05) trend = "rising"; // >5% increase
      else if (change < -0.05) trend = "falling"; // >5% decrease
    }

    // Calculate % from high/low
    const percentFromLow = allTimeLow > 0
      ? ((currentAvg - allTimeLow) / allTimeLow) * 100
      : 0;

    const percentFromHigh = allTimeHigh > 0
      ? ((currentAvg - allTimeHigh) / allTimeHigh) * 100
      : 0;

    const stats: PriceHistoryStats = {
      currentAvg: Math.round(currentAvg),
      thirtyDayAvg: Math.round(thirtyDayAvg),
      ninetyDayAvg: Math.round(ninetyDayAvg),
      allTimeHigh: Math.round(allTimeHigh),
      allTimeLow: Math.round(allTimeLow),
      trend,
      percentFromLow: Math.round(percentFromLow * 10) / 10, // 1 decimal
      percentFromHigh: Math.round(percentFromHigh * 10) / 10,
    };

    console.log(
      `[price-history] Retrieved ${records.length} records for "${normalizedName}" (${region}). Trend: ${trend}, Current avg: ${stats.currentAvg}`
    );

    return { history, stats };
  } catch (err: any) {
    console.error(`[price-history] getPriceHistory failed:`, err.message);
    return null;
  }
}
