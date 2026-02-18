/**
 * Perplexity Sonar — Web-augmented price search.
 * Used for:
 * 1. Real-time prices across ALL Indian retailers
 * 2. Product launch news/rumors
 */

import { getCached, setCache, CACHE_TTL } from "../utils/cache.js";

const PERPLEXITY_API_KEY = process.env.PERPLEXITY_API_KEY || "";
const SONAR_MODEL = "sonar";

interface PriceResult {
  retailer: string;
  price: number;
  currency: string;
  url?: string;
  offers?: string;
  inStock: boolean;
}

interface PriceSearchResult {
  productName: string;
  prices: PriceResult[];
  bestPrice: PriceResult | null;
  summary: string;
  citations: string[];
}

interface LaunchIntel {
  upcomingProduct: string | null;
  expectedDate: string | null;
  impact: string;
  confidence: number;
  summary: string;
  citations: string[];
}

/**
 * Search for current prices across Indian retailers.
 */
export async function searchPrices(query: string): Promise<PriceSearchResult> {
  const cacheKey = `prices:${query.toLowerCase().trim()}`;
  const cached = getCached<PriceSearchResult>(cacheKey);
  if (cached) return cached;

  const systemPrompt = `You are a price research assistant for Indian e-commerce. Return ONLY valid JSON.

Your job: Find the current price of a product across major Indian retailers.

Return this exact JSON structure:
{
  "productName": "exact product name with variant/storage",
  "prices": [
    {
      "retailer": "Amazon India",
      "price": 119900,
      "currency": "INR",
      "url": "product URL if found",
      "offers": "any special offers, EMI, bank discounts",
      "inStock": true
    }
  ],
  "bestPrice": { same structure as above, the cheapest option },
  "summary": "1-2 sentence summary of pricing landscape"
}

Retailers to check: Amazon India, Flipkart, Croma, Reliance Digital, Vijay Sales, Tata Cliq, and any other major Indian retailer.

Rules:
- Prices in INR (integer, no decimals). 1,19,900 = 119900
- Only include retailers that actually sell this product
- Include any ongoing offers, bank discounts, EMI options in the "offers" field
- If a retailer doesn't have the product, don't include it
- Sort prices low to high`;

  const userMessage = `Find the current price of "${query}" across all major Indian retailers. Include any ongoing offers or discounts.`;

  const response = await fetch("https://api.perplexity.ai/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${PERPLEXITY_API_KEY}`,
    },
    body: JSON.stringify({
      model: SONAR_MODEL,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userMessage },
      ],
      temperature: 0.1,
    }),
  });

  if (!response.ok) {
    throw new Error(`Perplexity API error: ${response.status}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || "";
  const citations = data.citations || [];

  const jsonMatch = content.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error("Could not parse price search response");
  }

  const result: PriceSearchResult = JSON.parse(jsonMatch[0]);
  result.citations = citations;

  setCache(cacheKey, result, CACHE_TTL.PRICES);
  return result;
}

/**
 * Search for upcoming product launches and news.
 */
export async function searchLaunchIntel(productName: string, category: string): Promise<LaunchIntel> {
  const cacheKey = `launch:${category.toLowerCase().trim()}`;
  const cached = getCached<LaunchIntel>(cacheKey);
  if (cached) return cached;

  const systemPrompt = `You are a product launch analyst. Return ONLY valid JSON.

Your job: Determine if there's an upcoming new version/model of a product that would affect buying decisions.

Return this exact JSON structure:
{
  "upcomingProduct": "name of upcoming product or null if none expected soon",
  "expectedDate": "expected launch date (e.g. 'September 2026') or null",
  "impact": "How this affects buying the current model — e.g. 'Current model typically drops 15-25% within 2 months of new launch'",
  "confidence": 0.0 to 1.0,
  "summary": "1-2 sentence summary for the user"
}

Rules:
- Only include launches expected within the next 6 months
- Base predictions on historical patterns + current rumors/leaks
- Be honest about confidence — don't fabricate dates
- If no new model is expected soon, set upcomingProduct to null`;

  const userMessage = `Is there an upcoming new version of "${productName}" (category: ${category}) expected to launch soon? What are the latest rumors and expected dates?`;

  const response = await fetch("https://api.perplexity.ai/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${PERPLEXITY_API_KEY}`,
    },
    body: JSON.stringify({
      model: SONAR_MODEL,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userMessage },
      ],
      temperature: 0.1,
    }),
  });

  if (!response.ok) {
    throw new Error(`Perplexity API error: ${response.status}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || "";
  const citations = data.citations || [];

  const jsonMatch = content.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error("Could not parse launch intel response");
  }

  const result: LaunchIntel = JSON.parse(jsonMatch[0]);
  result.citations = citations;

  setCache(cacheKey, result, CACHE_TTL.LAUNCH_NEWS);
  return result;
}
