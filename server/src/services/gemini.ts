/**
 * Gemini Flash Lite — Verdict generation engine.
 * Takes structured data (prices, history, launch intel, sale calendar)
 * and produces a BUY/WAIT/DONT_BUY verdict with reasoning.
 */

import { RegionConfig, getRegionConfig, formatPrice } from "../data/region-config.js";

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
const MODEL = "gemini-2.0-flash-lite";
const API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}`;

export interface VerdictInput {
  productName: string;
  currentPrices: Array<{ retailer: string; price: number; offers?: string }>;
  bestPrice: { retailer: string; price: number } | null;
  priceHistory?: {
    allTimeLow: number;
    allTimeHigh: number;
    avg90d: number;
    avg180d: number;
    currentVsAvg: string; // "above", "below", "at"
  };
  launchIntel?: {
    upcomingProduct: string | null;
    expectedDate: string | null;
    impact: string;
    confidence: number;
  };
  nextSaleEvent?: {
    name: string;
    date: string;
    historicalDiscount: string;
    daysAway?: number | null;
  };
  productCycle?: {
    brand: string;
    typicalLaunchMonth: number;
    lastLaunch: string;
  };
  region?: string;
  notAvailable?: boolean; // true when no retailers have the product (not launched / out of stock everywhere)
  deals?: Array<{
    type: string;
    title: string;
    discount?: string;
    retailer?: string;
    code?: string;
  }>;
}

export interface Verdict {
  verdict: "BUY_NOW" | "WAIT" | "DONT_BUY";
  confidence: number;
  reason: string;
  proAnalysis: {
    bestCurrentDeal: string;
    waitReason: string | null;
    estimatedSavings: string | null;
    bestTimeToBuy: string | null;
    launchAlert: string | null;
    topDeal: string | null;
  };
  shortReason: string; // One-line for free users
}

export async function generateVerdict(input: VerdictInput): Promise<Verdict> {
  const rc = getRegionConfig(input.region);
  const fp = (n: number) => formatPrice(n, rc);
  const sym = rc.currencySymbol;

  const prompt = `You are Savvit, an AI purchase timing advisor. Analyze the data below and decide: should the user BUY NOW, WAIT, or DONT BUY this product?

PRODUCT: ${input.productName}
REGION: ${rc.name} (${rc.currency})

CURRENT PRICES:
${input.notAvailable
  ? "⚠️ NO RETAILERS FOUND — This product appears to be unavailable in this region. It may not have launched yet, or it may be sold out everywhere. Make this VERY clear in your verdict."
  : input.currentPrices.map((p) => `- ${p.retailer}: ${fp(p.price ?? 0)}${p.offers ? ` (${p.offers})` : ""}`).join("\n")}

BEST PRICE: ${input.bestPrice ? `${fp(input.bestPrice.price ?? 0)} on ${input.bestPrice.retailer}` : "Unknown"}

${
  input.priceHistory
    ? `PRICE HISTORY:
- All-time low: ${fp(input.priceHistory.allTimeLow)}
- All-time high: ${fp(input.priceHistory.allTimeHigh)}
- 90-day average: ${fp(input.priceHistory.avg90d)}
- 180-day average: ${fp(input.priceHistory.avg180d)}
- Current vs average: ${input.priceHistory.currentVsAvg}`
    : "PRICE HISTORY: Not available yet"
}

${
  input.launchIntel?.upcomingProduct
    ? `LAUNCH INTEL:
- Upcoming: ${input.launchIntel.upcomingProduct}
- Expected: ${input.launchIntel.expectedDate || "Unknown"}
- Impact: ${input.launchIntel.impact}
- Confidence: ${(input.launchIntel.confidence * 100).toFixed(0)}%`
    : "LAUNCH INTEL: No upcoming replacement model detected"
}

${
  input.deals && input.deals.length > 0
    ? `ACTIVE DEALS & COUPONS:
${input.deals.map((d) => `- [${d.type.toUpperCase()}] ${d.title}${d.discount ? ` — ${d.discount}` : ""}${d.retailer ? ` (${d.retailer})` : ""}${d.code ? ` | Code: ${d.code}` : ""}`).join("\n")}`
    : "DEALS & COUPONS: None found"
}

${
  input.nextSaleEvent
    ? `NEXT SALE EVENT:
- ${input.nextSaleEvent.name} — ${input.nextSaleEvent.date}
- Historical discount: ${input.nextSaleEvent.historicalDiscount}
- Days away: ${input.nextSaleEvent.daysAway ?? "unknown"}`
    : "NEXT SALE: No major sale event in the next 60 days"
}

Return ONLY valid JSON:
{
  "verdict": "BUY_NOW" | "WAIT" | "DONT_BUY",
  "confidence": 0.0 to 1.0,
  "reason": "2-3 sentence explanation for the user",
  "proAnalysis": {
    "bestCurrentDeal": "Where to buy right now and why",
    "waitReason": "Why waiting is smarter (or null if BUY_NOW)",
    "estimatedSavings": "How much they could save by waiting (e.g. '${sym}8,000-12,000') or null",
    "bestTimeToBuy": "When to buy for best price or null",
    "launchAlert": "Info about upcoming new model (or null)",
    "topDeal": "The single best deal/coupon to highlight (or null if no deals)"
  },
  "shortReason": "One concise line (max 60 chars) for the verdict badge"
}

DECISION RULES:
- BUY_NOW: No major sale coming within 30 days AND no new model within 60 days. Also BUY_NOW if strong active deals/coupons are available right now, OR if the product is at a good price with no imminent reason to wait.
- WAIT: Major sale coming within 30 days (NOT 60+ days — that's too far to wait), OR new model launching within 45 days with high confidence, OR price is clearly inflated/above normal.
- DONT_BUY: New model launching very soon (<30 days), OR clear price gouging, OR product is discontinued/outdated with a much better successor available at similar price.
- CRITICAL: Do NOT recommend WAIT just because a sale exists 2+ months away. Users want to buy things — a sale 60+ days out is NOT a reason to wait. Most people won't wait 2 months to save 10-15%.
- If the next sale is 45+ days away and the current price is reasonable, recommend BUY_NOW.
- If there are strong active deals/coupons right now, lean BUY_NOW — a bird in hand beats a speculative future sale.
- Be specific with savings estimates and dates — use ${sym} for currency
- Factor in active deals/coupons — if a bank offer or coupon effectively lowers the price significantly, mention it in your reasoning
- shortReason should be punchy and actionable: "Great price — grab it" or "New model drops in 3 weeks" or "Price spike — avoid" or "Sale in 2 weeks — worth waiting"
- topDeal: highlight the single best deal if any exist (e.g. "Use code SAVE10 on Amazon for 10% off" or "HDFC card: extra ${sym}5,000 off on Flipkart")`;

  const response = await fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 1024,
      },
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Gemini API error: ${response.status} — ${errText}`);
  }

  const data = await response.json();
  const content = data.candidates?.[0]?.content?.parts?.[0]?.text || "";

  const jsonMatch = content.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error("Could not parse verdict response from Gemini");
  }

  return JSON.parse(jsonMatch[0]) as Verdict;
}
