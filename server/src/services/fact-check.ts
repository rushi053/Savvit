/**
 * Fact-checking layer for launch intel.
 * Cross-references Perplexity's claims against:
 * 1. Our known product cycles (hard data)
 * 2. Date sanity checks
 * 3. Citation quality scoring
 * 
 * Outputs a verified/unverified flag + adjusted confidence.
 */

import { findProductCycle, PRODUCT_CYCLES } from "../data/product-cycles.js";

interface LaunchIntel {
  upcomingProduct: string | null;
  expectedDate: string | null;
  impact: string;
  confidence: number;
  summary: string;
  citations: string[];
}

interface FactCheckResult {
  verified: boolean;           // true = consistent with known data
  adjustedConfidence: number;  // may lower confidence if claims are suspect
  warnings: string[];          // issues found (for logging)
  cleanedSummary: string;      // summary with corrections applied
  citationQuality: "high" | "medium" | "low" | "none";
}

// Credible tech news sources
const CREDIBLE_SOURCES = [
  "macrumors.com", "9to5mac.com", "9to5google.com", "theverge.com",
  "techcrunch.com", "arstechnica.com", "wired.com", "engadget.com",
  "tomsguide.com", "tomshardware.com", "gsmarena.com", "notebookcheck.net",
  "bloomberg.com", "reuters.com", "nytimes.com", "wsj.com",
  "apple.com", "samsung.com", "google.com", "sony.com", "microsoft.com",
  "91mobiles.com", "digit.in", "gadgets360.com", "xda-developers.com",
  "androidauthority.com", "cnet.com", "pcmag.com",
];

// Low-quality / often-wrong sources
const LOW_QUALITY_SOURCES = [
  "medium.com", "quora.com", "reddit.com", "youtube.com",
  "twitter.com", "x.com", "facebook.com", "tiktok.com",
  "blogspot.com", "wordpress.com",
];

/**
 * Score citation quality based on source domains.
 */
function scoreCitations(citations: string[]): "high" | "medium" | "low" | "none" {
  if (!citations || citations.length === 0) return "none";

  let credibleCount = 0;
  let lowQualityCount = 0;

  for (const url of citations) {
    const lower = url.toLowerCase();
    if (CREDIBLE_SOURCES.some(s => lower.includes(s))) credibleCount++;
    if (LOW_QUALITY_SOURCES.some(s => lower.includes(s))) lowQualityCount++;
  }

  if (credibleCount >= 2) return "high";
  if (credibleCount >= 1) return "medium";
  if (lowQualityCount > credibleCount) return "low";
  return "medium"; // unknown sources — neutral
}

/**
 * Parse a vague date string like "September 2026" or "Q3 2026" into a Date.
 * Returns null if unparseable.
 */
function parseVagueDate(dateStr: string | null): Date | null {
  if (!dateStr) return null;
  
  const s = dateStr.trim();

  // "September 2026" / "March 2025"
  const monthYear = s.match(/^(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})$/i);
  if (monthYear) {
    const months: Record<string, number> = {
      january: 0, february: 1, march: 2, april: 3, may: 4, june: 5,
      july: 6, august: 7, september: 8, october: 9, november: 10, december: 11,
    };
    return new Date(parseInt(monthYear[2]), months[monthYear[1].toLowerCase()], 15);
  }

  // "Q1 2026" / "Q3 2025"
  const quarterYear = s.match(/^Q([1-4])\s+(\d{4})$/i);
  if (quarterYear) {
    const qMonth = (parseInt(quarterYear[1]) - 1) * 3 + 1; // Q1=1, Q2=4, Q3=7, Q4=10
    return new Date(parseInt(quarterYear[2]), qMonth, 15);
  }

  // "Early/Mid/Late 2026"
  const vagueYear = s.match(/^(early|mid|late)\s+(\d{4})$/i);
  if (vagueYear) {
    const monthMap: Record<string, number> = { early: 2, mid: 5, late: 9 };
    return new Date(parseInt(vagueYear[2]), monthMap[vagueYear[1].toLowerCase()], 15);
  }

  // Just a year "2026"
  const justYear = s.match(/^(\d{4})$/);
  if (justYear) {
    return new Date(parseInt(justYear[1]), 5, 15); // assume mid-year
  }

  // Try native parse as last resort
  const parsed = new Date(s);
  return isNaN(parsed.getTime()) ? null : parsed;
}

/**
 * Fact-check launch intel against known product cycles and common sense.
 */
export function factCheckLaunchIntel(
  intel: LaunchIntel,
  productQuery: string,
): FactCheckResult {
  const warnings: string[] = [];
  let adjustedConfidence = intel.confidence;
  let verified = true;
  const now = new Date();

  const citationQuality = scoreCitations(intel.citations);
  const cycle = findProductCycle(productQuery);

  // === Check 1: Citation quality affects confidence ===
  if (citationQuality === "none") {
    adjustedConfidence *= 0.5;
    warnings.push("No citations provided for launch intel");
  } else if (citationQuality === "low") {
    adjustedConfidence *= 0.7;
    warnings.push("Launch intel based on low-quality sources");
  }

  // === Check 2: If no upcoming product claimed, that's usually safe ===
  if (!intel.upcomingProduct) {
    // No claim = nothing to fact-check
    return {
      verified: true,
      adjustedConfidence: Math.min(adjustedConfidence, 1.0),
      warnings,
      cleanedSummary: intel.summary,
      citationQuality,
    };
  }

  // === Check 3: Parse and validate the expected date ===
  const expectedDate = parseVagueDate(intel.expectedDate);
  
  if (expectedDate) {
    // 3a: Date is in the past — this is a statement about what already happened, not a prediction
    if (expectedDate < now) {
      // This is fine — Perplexity is saying "X already launched on Y date"
      // Don't flag as hallucination, it's historical context
      // But do verify it's reasonable against our product cycle
      if (cycle) {
        const expectedMonth = expectedDate.getMonth() + 1;
        const typicalMonth = cycle.typicalLaunchMonth;
        const monthDiff = Math.abs(expectedMonth - typicalMonth);
        // Allow 2-month variance from typical launch month
        if (monthDiff > 2 && monthDiff < 10) { // 10 accounts for Dec→Jan wrapping
          warnings.push(
            `Claimed launch month (${expectedMonth}) differs from typical ${cycle.brand} ${cycle.productLine} launch month (${typicalMonth})`
          );
          adjustedConfidence *= 0.8;
        }
      }
    }

    // 3b: Date is way too far in the future (>18 months) — likely hallucinated
    const monthsAway = (expectedDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24 * 30);
    if (monthsAway > 18) {
      verified = false;
      adjustedConfidence *= 0.3;
      warnings.push(`Expected date is ${Math.round(monthsAway)} months away — too far to be reliable`);
    }

    // 3c: Verify against product cycle timing
    if (cycle && expectedDate > now) {
      const expectedMonth = expectedDate.getMonth() + 1;
      const typicalMonth = cycle.typicalLaunchMonth;
      const monthDiff = Math.abs(expectedMonth - typicalMonth);
      const wrappedDiff = Math.min(monthDiff, 12 - monthDiff);
      
      if (wrappedDiff > 3) {
        warnings.push(
          `Claimed launch in month ${expectedMonth} but ${cycle.brand} ${cycle.productLine} typically launches in month ${typicalMonth}`
        );
        adjustedConfidence *= 0.6;
        verified = false;
      }
    }
  } else if (intel.expectedDate) {
    // Couldn't parse the date at all
    warnings.push(`Could not parse expected date: "${intel.expectedDate}"`);
    adjustedConfidence *= 0.7;
  }

  // === Check 4: Product name sanity ===
  // Check if the claimed upcoming product makes sense (e.g. "iPhone 20" in 2026 is suspicious)
  const productNumberMatch = intel.upcomingProduct.match(/(\d+)/);
  if (productNumberMatch) {
    const claimedNumber = parseInt(productNumberMatch[1]);
    const queryNumberMatch = productQuery.match(/(\d+)/);
    if (queryNumberMatch) {
      const currentNumber = parseInt(queryNumberMatch[1]);
      // If claimed successor is more than 2 generations ahead, suspicious
      if (claimedNumber > currentNumber + 2) {
        warnings.push(
          `Claimed successor "${intel.upcomingProduct}" is ${claimedNumber - currentNumber} generations ahead of queried "${productQuery}"`
        );
        adjustedConfidence *= 0.5;
        verified = false;
      }
    }
  }

  // === Check 5: Summary contains contradictions ===
  const summary = intel.summary.toLowerCase();
  // "launched" + future date = contradiction
  if (expectedDate && expectedDate > now) {
    if (summary.includes("launched") || summary.includes("was released") || summary.includes("came out")) {
      // Claims a future product "launched" — might be using past tense for a future event
      // This is a common LLM hallucination pattern
      warnings.push("Summary uses past tense for a future product launch — possible hallucination");
      adjustedConfidence *= 0.6;
      verified = false;
    }
  }

  // Clamp confidence
  adjustedConfidence = Math.max(0.1, Math.min(1.0, adjustedConfidence));

  // Clean up summary if needed
  let cleanedSummary = intel.summary;
  if (!verified && warnings.length > 0) {
    cleanedSummary += " (Note: Some details could not be fully verified)";
  }

  return {
    verified,
    adjustedConfidence,
    warnings,
    cleanedSummary,
    citationQuality,
  };
}
