/**
 * Gemini Flash Lite — Verdict generation engine.
 * Takes structured data (prices, history, launch intel, sale calendar)
 * and produces a BUY/WAIT/DONT_BUY verdict with reasoning.
 */

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
  };
  productCycle?: {
    brand: string;
    typicalLaunchMonth: number;
    lastLaunch: string;
  };
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
  };
  shortReason: string; // One-line for free users
}

export async function generateVerdict(input: VerdictInput): Promise<Verdict> {
  const prompt = `You are Savvit, an AI purchase timing advisor. Analyze the data below and decide: should the user BUY NOW, WAIT, or DONT BUY this product?

PRODUCT: ${input.productName}

CURRENT PRICES:
${input.currentPrices.map((p) => `- ${p.retailer}: ₹${p.price.toLocaleString("en-IN")}${p.offers ? ` (${p.offers})` : ""}`).join("\n")}

BEST PRICE: ${input.bestPrice ? `₹${input.bestPrice.price.toLocaleString("en-IN")} on ${input.bestPrice.retailer}` : "Unknown"}

${
  input.priceHistory
    ? `PRICE HISTORY:
- All-time low: ₹${input.priceHistory.allTimeLow.toLocaleString("en-IN")}
- All-time high: ₹${input.priceHistory.allTimeHigh.toLocaleString("en-IN")}
- 90-day average: ₹${input.priceHistory.avg90d.toLocaleString("en-IN")}
- 180-day average: ₹${input.priceHistory.avg180d.toLocaleString("en-IN")}
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
  input.nextSaleEvent
    ? `NEXT SALE EVENT:
- ${input.nextSaleEvent.name} — ${input.nextSaleEvent.date}
- Historical discount: ${input.nextSaleEvent.historicalDiscount}`
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
    "estimatedSavings": "How much they could save by waiting (e.g. '₹8,000-12,000') or null",
    "bestTimeToBuy": "When to buy for best price (e.g. 'October 2026 during Amazon Great Indian Festival') or null",
    "launchAlert": "Info about upcoming new model (or null)"
  },
  "shortReason": "One concise line (max 60 chars) for the verdict badge"
}

DECISION RULES:
- BUY_NOW: Price is at/near historical low, no major sale coming within 30 days, no new model within 60 days
- WAIT: Major sale coming within 60 days, OR new model launching within 90 days, OR price is significantly above average
- DONT_BUY: Price is at historical high, OR new model launching very soon (<30 days), OR clear price gouging
- When unsure, lean WAIT — it's safer advice
- Be specific with savings estimates and dates
- shortReason should be punchy: "Near all-time low" or "New model in 5 weeks" or "Price spike — avoid"`;

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
