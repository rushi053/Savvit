/**
 * Perplexity Sonar — Web-augmented price search.
 * Used for:
 * 1. Real-time prices across retailers (region-aware)
 * 2. Product launch news/rumors
 */

import { getCached, setCache, CACHE_TTL } from "../utils/cache.js";
import { RegionConfig, getRegionConfig, getRetailerSearchUrl, isTrustedRetailer, getRetailerDomains } from "../data/region-config.js";

const PERPLEXITY_API_KEY = process.env.PERPLEXITY_API_KEY || "";
const SONAR_MODEL = "sonar";

interface PriceResult {
  retailer: string;
  price: number;
  currency: string;
  url?: string;
  offers?: string;
  inStock: boolean;
  trusted?: boolean;
}

interface PriceSearchResult {
  productName: string;
  productImage: string | null;
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
 * Pick the best product image from Perplexity's returned images.
 * Aggressively filters for actual product photos on white/clean backgrounds.
 */
function pickBestProductImage(
  images: Array<{ image_url: string; origin_url?: string; title?: string }>
): string | null {
  if (!images || images.length === 0) return null;

  const scored = images.map((img) => {
    let score = 0;
    const url = img.image_url.toLowerCase();
    const origin = (img.origin_url || "").toLowerCase();
    const title = (img.title || "").toLowerCase();

    // === HARD PENALIZE — likely not product photos ===
    if (url.includes("ytimg.com") || origin.includes("youtube.com")) score -= 20;
    if (origin.includes("tiktok") || origin.includes("vimeo") || origin.includes("dailymotion")) score -= 20;
    if (origin.includes("instagram") || origin.includes("twitter.com") || origin.includes("x.com")) score -= 15;
    if (origin.includes("reddit.com") || origin.includes("quora.com")) score -= 15;
    // Blog/news/review sites often use lifestyle shots
    if (origin.includes("blog") || origin.includes("news") || origin.includes("review")) score -= 5;
    if (title.includes("review") || title.includes("hands on") || title.includes("hands-on")) score -= 5;
    if (title.includes("unboxing") || title.includes("vs ") || title.includes("comparison")) score -= 5;
    if (title.includes("photographer") || title.includes("taking photo") || title.includes("lifestyle")) score -= 10;

    // === STRONG PREFER — official product images ===
    // Manufacturer sites (official product shots, white bg)
    const manufacturerSites = ["apple.com", "samsung.com", "sony.com", "canon.com", "nikon.com",
      "lg.com", "dell.com", "lenovo.com", "asus.com", "hp.com", "microsoft.com", "google.com/store",
      "nintendo.com", "playstation.com", "xbox.com", "dyson.com", "bose.com", "oneplus.com"];
    if (manufacturerSites.some((s) => origin.includes(s))) score += 15;

    // Retailer product pages (usually clean product shots)
    const retailerSites = ["amazon.", "flipkart.com", "bestbuy.com", "walmart.com", "target.com",
      "croma.com", "jbhifi.com", "currys.co.uk", "mediamarkt", "reliance", "bhphotovideo"];
    if (retailerSites.some((s) => origin.includes(s))) score += 10;

    // Spec/database sites (clean product renders)
    const specSites = ["gsmarena.com", "notebookcheck", "rtings.com", "kimovil.com", "smartprix.com",
      "91mobiles.com", "digit.in", "gadgets360", "pricebaba.com"];
    if (specSites.some((s) => origin.includes(s))) score += 8;

    // CDN URLs from retailers often have product images
    if (url.includes("/images/i/") || url.includes("/product/") || url.includes("/products/")) score += 3;
    if (url.includes("m.media-amazon") || url.includes("rukminim")) score += 8; // Amazon/Flipkart CDNs

    // Image format bonus
    if (url.endsWith(".png")) score += 3; // PNG = likely product render on transparent bg
    if (url.endsWith(".jpg") || url.endsWith(".jpeg") || url.endsWith(".webp")) score += 1;

    // Penalize tiny images (thumbnails) — check URL hints
    if (url.includes("thumb") || url.includes("_small") || url.includes("_xs") || url.includes("50x50")) score -= 5;
    // Prefer larger images
    if (url.includes("_large") || url.includes("_xl") || url.includes("1200") || url.includes("1000")) score += 2;

    return { ...img, score };
  });

  scored.sort((a, b) => b.score - a.score);

  // Only return if the best image has a positive score — otherwise skip
  const best = scored[0];
  if (best && best.score > 0) {
    console.log(`[image] picked: score=${best.score} origin=${best.origin_url} url=${best.image_url.substring(0, 80)}`);
    return best.image_url;
  }

  console.log(`[image] no good image found (best score: ${scored[0]?.score})`);
  return null;
}

/**
 * Detect which retailer a URL belongs to (returns display name or null).
 */
function detectRetailerFromUrl(url: string): string | null {
  const u = url.toLowerCase();
  const patterns: [RegExp | string, string][] = [
    ["amazon.in", "Amazon India"],
    ["amazon.co.uk", "Amazon UK"],
    ["amazon.de", "Amazon Germany"],
    ["amazon.co.jp", "Amazon Japan"],
    ["amazon.ca", "Amazon Canada"],
    ["amazon.com.au", "Amazon Australia"],
    ["amazon.fr", "Amazon France"],
    ["amazon.com", "Amazon"],
    ["flipkart.com", "Flipkart"],
    ["croma.com", "Croma"],
    ["reliancedigital.in", "Reliance Digital"],
    ["vijaysales.com", "Vijay Sales"],
    ["tatacliq.com", "Tata Cliq"],
    ["bestbuy.com", "Best Buy"],
    ["walmart.com", "Walmart"],
    ["target.com", "Target"],
    ["bhphotovideo.com", "B&H Photo"],
    ["costco.com", "Costco"],
    ["newegg.com", "Newegg"],
    ["jbhifi.com.au", "JB Hi-Fi"],
    ["currys.co.uk", "Currys"],
    ["argos.co.uk", "Argos"],
    ["mediamarkt", "MediaMarkt"],
    ["saturn.de", "Saturn"],
    ["otto.de", "Otto"],
    ["canadacomputers.com", "Canada Computers"],
    ["ldlc.com", "LDLC"],
    ["fnac.com", "Fnac"],
    ["darty.com", "Darty"],
    ["biccamera.com", "Bic Camera"],
    ["yodobashi.com", "Yodobashi"],
    ["apple.com", "Apple Store"],
    ["samsung.com", "Samsung Store"],
    ["store.google.com", "Google Store"],
  ];
  for (const [pattern, name] of patterns) {
    if (u.includes(typeof pattern === "string" ? pattern : "")) return name;
  }
  return null;
}

/**
 * Search for current prices across retailers (region-aware).
 * If sourceUrl is provided, that retailer is guaranteed in results.
 */
export async function searchPrices(query: string, region?: string, sourceUrl?: string): Promise<PriceSearchResult> {
  const regionConfig = getRegionConfig(region);
  const cacheKey = `prices:${regionConfig.code}:${query.toLowerCase().trim()}`;
  const cached = getCached<PriceSearchResult>(cacheKey);
  if (cached) return cached;

  const sourceRetailer = sourceUrl ? detectRetailerFromUrl(sourceUrl) : null;
  if (sourceRetailer) {
    console.log(`[perplexity] source retailer detected: ${sourceRetailer} from ${sourceUrl}`);
  }
  const retailerDomains = getRetailerDomains(regionConfig);

  const systemPrompt = `You are a price research assistant for ${regionConfig.name} e-commerce. Return ONLY valid JSON.

Your job: Find the current price of a product by checking EACH of these retailer websites individually: ${retailerDomains}

You MUST check each retailer's website. Do not skip any — if a retailer sells the product, include their price.

Return this exact JSON structure:
{
  "productName": "exact product name with variant/storage",
  "productImage": "leave empty string, will be auto-generated",
  "prices": [
    {
      "retailer": "retailer name",
      "price": 99900,
      "currency": "${regionConfig.currency}",
      "url": "leave empty string, will be auto-generated",
      "offers": "any special offers, discounts, bundle deals",
      "inStock": true
    }
  ],
  "bestPrice": { same structure as above, the cheapest option },
  "summary": "1-2 sentence summary of pricing landscape"
}

Rules:
- Prices in ${regionConfig.currency} (integer, no decimals)
- Check EVERY retailer listed above — only exclude if they genuinely don't sell the product
- Include any ongoing offers, bank discounts, bundle deals in the "offers" field
- Sort prices low to high`;

  // If query contains an ASIN or item ID, tell Perplexity to look it up
  const isASINQuery = /Amazon ASIN [A-Z0-9]{10}/i.test(query);
  const isFlipkartQuery = /Flipkart item /i.test(query);
  let userMessage: string;
  if (isASINQuery) {
    userMessage = `Identify this product and find its current price across all major ${regionConfig.name} retailers: ${query}. First identify what the product is from the ASIN, then find prices. IMPORTANT: You MUST include the Amazon price for this product since it came from Amazon. Also check ${regionConfig.retailers.filter(r => !r.toLowerCase().includes('amazon')).join(', ')}. Include any ongoing offers or discounts.`;
  } else if (isFlipkartQuery) {
    userMessage = `Identify this product and find its current price across all major ${regionConfig.name} retailers: ${query}. First identify what the product is, then find prices. IMPORTANT: You MUST include the Flipkart price. Include any ongoing offers or discounts.`;
  } else if (sourceRetailer) {
    userMessage = `Find the current price of "${query}" across all major ${regionConfig.name} retailers. IMPORTANT: The user found this product on ${sourceRetailer}, so you MUST include ${sourceRetailer}'s price. Also check ${regionConfig.retailers.filter(r => r.toLowerCase() !== sourceRetailer.toLowerCase()).join(', ')}. Include any ongoing offers or discounts.`;
  } else {
    userMessage = `Find the current price of "${query}" in ${regionConfig.name}. Check EACH retailer individually: ${retailerDomains}. Visit each website and report their current price. Include any ongoing offers or discounts.`;
  }

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
      return_images: true,
    }),
  });

  if (!response.ok) {
    throw new Error(`Perplexity API error: ${response.status}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || "";
  const citations = data.citations || [];

  // Extract best product image from Perplexity's returned images
  const images: Array<{ image_url: string; origin_url?: string; title?: string }> = data.images || [];
  // Prefer images NOT from YouTube, prefer retailer/manufacturer sites
  const productImage = pickBestProductImage(images);

  const jsonMatch = content.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    console.error("[perplexity] No JSON in response:", content.substring(0, 300));
    throw new Error("Could not parse price search response");
  }

  let result: PriceSearchResult;
  try {
    result = JSON.parse(jsonMatch[0]);
  } catch (e) {
    console.error("[perplexity] JSON parse failed:", jsonMatch[0].substring(0, 300));
    throw new Error("Could not parse price search response");
  }

  // Defensive: ensure prices is an array with valid data
  if (!Array.isArray(result.prices)) {
    console.error("[perplexity] prices is not an array:", typeof result.prices);
    result.prices = [];
  }
  // Ensure every price is a number
  result.prices = result.prices.map((p) => ({
    ...p,
    price: typeof p.price === "number" ? p.price : parseInt(String(p.price).replace(/[^0-9]/g, ""), 10) || 0,
  }));
  if (result.bestPrice) {
    result.bestPrice.price = typeof result.bestPrice.price === "number"
      ? result.bestPrice.price
      : parseInt(String(result.bestPrice.price).replace(/[^0-9]/g, ""), 10) || 0;
  }
  result.citations = citations;
  result.productImage = productImage;

  // Filter out useless entries: price 0 + out of stock
  result.prices = result.prices.filter((p) => {
    if (p.price <= 0 && p.inStock === false) return false;
    if (p.price <= 0 && !p.offers) return false; // no price AND no offers = useless
    return true;
  });
  // If bestPrice is 0, clear it
  if (result.bestPrice && result.bestPrice.price <= 0) {
    result.bestPrice = null;
  }

  // Replace LLM-hallucinated URLs with real search URLs (region-aware)
  // But preserve the source URL if it matches the source retailer
  const productName = result.productName || query;
  for (const price of result.prices) {
    price.url = getRetailerSearchUrl(price.retailer, productName, regionConfig);
  }
  if (result.bestPrice) {
    result.bestPrice.url = getRetailerSearchUrl(result.bestPrice.retailer, productName, regionConfig);
  }
  // Override source retailer's URL with the actual direct link
  if (sourceRetailer && sourceUrl) {
    for (const p of result.prices) {
      if (p.retailer.toLowerCase().includes(sourceRetailer.toLowerCase()) ||
          sourceRetailer.toLowerCase().includes(p.retailer.toLowerCase())) {
        p.url = sourceUrl;
        break;
      }
    }
    if (result.bestPrice &&
        (result.bestPrice.retailer.toLowerCase().includes(sourceRetailer.toLowerCase()) ||
         sourceRetailer.toLowerCase().includes(result.bestPrice.retailer.toLowerCase()))) {
      result.bestPrice.url = sourceUrl;
    }
  }

  // Tag each retailer as trusted or not, then sort: trusted first (by price), untrusted after
  for (const p of result.prices) {
    p.trusted = isTrustedRetailer(p.retailer, regionConfig);
  }
  result.prices.sort((a, b) => {
    // Trusted first
    if (a.trusted && !b.trusted) return -1;
    if (!a.trusted && b.trusted) return 1;
    // Within same trust level, sort by price (0 = unknown, push to end)
    const pa = a.price || Infinity;
    const pb = b.price || Infinity;
    return pa - pb;
  });

  // bestPrice = cheapest TRUSTED retailer with a real price
  const cheapestTrusted = result.prices.find((p) => p.trusted && p.price > 0);
  if (cheapestTrusted) {
    result.bestPrice = { ...cheapestTrusted };
  } else if (result.prices.length > 0 && result.prices[0].price > 0) {
    // Fallback: cheapest overall if no trusted retailer found
    result.bestPrice = { ...result.prices[0] };
  }

  // Guarantee source retailer is in the list (user came from that retailer's page)
  if (sourceRetailer && sourceUrl) {
    const hasSource = result.prices.some(
      (p) => p.retailer.toLowerCase().includes(sourceRetailer.toLowerCase()) ||
             sourceRetailer.toLowerCase().includes(p.retailer.toLowerCase())
    );
    if (!hasSource) {
      console.log(`[perplexity] source retailer "${sourceRetailer}" missing from results, adding with source URL`);
      // Add the source retailer — we know they sell it (user was on their page),
      // but we don't have the price, so mark it with price 0 and a note
      result.prices.push({
        retailer: sourceRetailer,
        price: 0,
        currency: regionConfig.currency,
        url: sourceUrl,
        offers: "Price available on retailer page",
        inStock: true,
        trusted: true, // user was literally on their page
      });
    } else {
      // Source retailer exists — replace its URL with the actual source URL (direct link)
      for (const p of result.prices) {
        if (p.retailer.toLowerCase().includes(sourceRetailer.toLowerCase()) ||
            sourceRetailer.toLowerCase().includes(p.retailer.toLowerCase())) {
          p.url = sourceUrl;
          break;
        }
      }
    }
  }

  // Only cache if we got meaningful results
  if (result.prices.length > 0 && result.prices.some((p) => p.price > 0)) {
    setCache(cacheKey, result, CACHE_TTL.PRICES);
  }
  return result;
}

// ── Deals & Coupons Search ──────────────────────────────────────────

interface Deal {
  type: "coupon" | "bank_offer" | "cashback" | "exchange" | "student" | "bundle" | "sale" | "other";
  title: string;
  description: string;
  code?: string;        // coupon code if applicable
  retailer?: string;    // which retailer this applies to
  discount?: string;    // e.g. "10% off", "₹5,000 off", "$50 off"
  validUntil?: string;  // expiry if known
  source?: string;      // where this deal was found
}

interface DealsResult {
  deals: Deal[];
  summary: string;
  citations: string[];
}

/**
 * Search for active coupons, bank offers, cashback deals, exchange offers,
 * student discounts, and bundle deals for a product — region-aware.
 */
export async function searchDeals(query: string, region?: string): Promise<DealsResult> {
  const regionConfig = getRegionConfig(region);
  const cacheKey = `deals:${regionConfig.code}:${query.toLowerCase().trim()}`;
  const cached = getCached<DealsResult>(cacheKey);
  if (cached) return cached;

  // Region-specific deal types to search for
  const regionDealHints: Record<string, string> = {
    IN: "bank card offers (HDFC, ICICI, SBI, Axis, Kotak, AMEX), No-Cost EMI, exchange/trade-in offers, Flipkart SuperCoins, Amazon Pay cashback, Croma gift card offers",
    US: "promo codes, credit card cashback (Chase, Amex, Citi), trade-in programs (Apple, Best Buy, Amazon), student/military/first responder discounts, price match guarantees, Honey/Rakuten cashback",
    UK: "voucher codes, cashback (TopCashback, Quidco), student discount (UNiDAYS, Student Beans), trade-in offers, Currys price promise",
    DE: "Gutscheincodes, Cashback (Shoop, iGraal), trade-in programs, MediaMarkt/Saturn club offers, student discounts",
    CA: "promo codes, Aeroplan/PC Optimum points, trade-in offers, student discounts, price match guarantees, Rakuten cashback",
    AU: "promo codes, cashback (ShopBack, Cashrewards), trade-in programs, student discounts (UNiDAYS), JB Hi-Fi price match",
    JP: "クーポン (coupons), point programs (Rakuten Points, T-Points, d-Points), trade-in offers, student discounts",
    FR: "codes promo, cashback (iGraal, Poulpeo), offres de reprise (trade-in), remises étudiantes, offres de remboursement",
  };

  const dealHints = regionDealHints[regionConfig.code] || "promo codes, cashback, trade-in offers, student discounts";

  const systemPrompt = `You are a deal-finding assistant for ${regionConfig.name}. Return ONLY valid JSON.

Your job: Find ALL active coupons, discount codes, bank offers, cashback deals, exchange/trade-in offers, student discounts, and bundle deals for a specific product.

Return this exact JSON structure:
{
  "deals": [
    {
      "type": "coupon|bank_offer|cashback|exchange|student|bundle|sale|other",
      "title": "Short title of the deal",
      "description": "Details — what the user gets and how to claim it",
      "code": "COUPON_CODE or null if not a code-based deal",
      "retailer": "Which retailer this deal is on",
      "discount": "e.g. 10% off, ${regionConfig.currencySymbol}5000 off, 5% cashback",
      "validUntil": "Expiry date if known, or null",
      "source": "Where you found this info"
    }
  ],
  "summary": "1-2 sentence overview of the best deals available right now"
}

Types of deals to look for in ${regionConfig.name}:
${dealHints}

Rules:
- Only include CURRENTLY ACTIVE deals (not expired)
- Include the coupon/promo code when available
- Be specific about conditions (min purchase, specific cards, etc.)
- If no deals found, return empty deals array with summary "No active deals found"
- Sort by value — biggest savings first
- Include deals from ALL major ${regionConfig.name} retailers that sell this product`;

  const userMessage = `Find all active coupons, promo codes, bank offers, cashback deals, exchange offers, and discounts for "${query}" in ${regionConfig.name}. Check all major retailers: ${regionConfig.retailers.join(", ")}. Include any active sale events.`;

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
    console.error("[perplexity:deals] No JSON in response:", content.substring(0, 300));
    return { deals: [], summary: "Could not find deals information", citations };
  }

  let result: DealsResult;
  try {
    result = JSON.parse(jsonMatch[0]);
  } catch {
    console.error("[perplexity:deals] JSON parse failed");
    return { deals: [], summary: "Could not parse deals information", citations };
  }

  if (!Array.isArray(result.deals)) result.deals = [];
  result.citations = citations;

  // Cache deals for 6 hours (same as prices — deals change frequently)
  if (result.deals.length > 0) {
    setCache(cacheKey, result, CACHE_TTL.PRICES);
  }

  return result;
}

/**
 * Search for upcoming product launches and news.
 */
export async function searchLaunchIntel(productName: string, category: string): Promise<LaunchIntel> {
  const cacheKey = `launch:${productName.toLowerCase().trim()}:${category.toLowerCase().trim()}`;
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
