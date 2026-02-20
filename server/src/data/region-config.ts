/**
 * Region configuration — retailers, currencies, and search URLs per market.
 * Supported regions: IN, US, UK, DE, CA, AU, FR, ES, IT, JP
 * Fallback: US
 */

export interface RegionConfig {
  code: string;
  name: string;
  currency: string;
  currencySymbol: string;
  locale: string; // for number formatting
  retailers: string[]; // prompt hint — which retailers to search
  amazonDomain: string;
  searchUrls: Record<string, (q: string) => string>;
}

const REGIONS: Record<string, RegionConfig> = {
  IN: {
    code: "IN",
    name: "India",
    currency: "INR",
    currencySymbol: "₹",
    locale: "en-IN",
    retailers: [
      "Amazon India",
      "Flipkart",
      "Croma",
      "Reliance Digital",
      "Vijay Sales",
      "Tata Cliq",
    ],
    amazonDomain: "amazon.in",
    searchUrls: {
      "amazon india": (q) => `https://www.amazon.in/s?k=${encodeURIComponent(q)}`,
      amazon: (q) => `https://www.amazon.in/s?k=${encodeURIComponent(q)}`,
      flipkart: (q) => `https://www.flipkart.com/search?q=${encodeURIComponent(q)}`,
      croma: (q) => `https://www.croma.com/searchB?q=${encodeURIComponent(q)}`,
      "reliance digital": (q) => `https://www.reliancedigital.in/search?q=${encodeURIComponent(q)}`,
      "vijay sales": (q) => `https://www.vijaysales.com/search/${encodeURIComponent(q)}`,
      "tata cliq": (q) => `https://www.tatacliq.com/search/?searchCategory=all&text=${encodeURIComponent(q)}`,
      iplanet: (q) => `https://iplanet.one/search?q=${encodeURIComponent(q)}`,
    },
  },

  US: {
    code: "US",
    name: "United States",
    currency: "USD",
    currencySymbol: "$",
    locale: "en-US",
    retailers: [
      "Amazon",
      "Best Buy",
      "Walmart",
      "Target",
      "B&H Photo",
      "Costco",
      "Newegg",
    ],
    amazonDomain: "amazon.com",
    searchUrls: {
      amazon: (q) => `https://www.amazon.com/s?k=${encodeURIComponent(q)}`,
      "best buy": (q) => `https://www.bestbuy.com/site/searchpage.jsp?st=${encodeURIComponent(q)}`,
      bestbuy: (q) => `https://www.bestbuy.com/site/searchpage.jsp?st=${encodeURIComponent(q)}`,
      walmart: (q) => `https://www.walmart.com/search?q=${encodeURIComponent(q)}`,
      target: (q) => `https://www.target.com/s?searchTerm=${encodeURIComponent(q)}`,
      "b&h photo": (q) => `https://www.bhphotovideo.com/c/search?q=${encodeURIComponent(q)}`,
      "b&h": (q) => `https://www.bhphotovideo.com/c/search?q=${encodeURIComponent(q)}`,
      costco: (q) => `https://www.costco.com/CatalogSearch?dept=All&keyword=${encodeURIComponent(q)}`,
      newegg: (q) => `https://www.newegg.com/p/pl?d=${encodeURIComponent(q)}`,
    },
  },

  UK: {
    code: "UK",
    name: "United Kingdom",
    currency: "GBP",
    currencySymbol: "£",
    locale: "en-GB",
    retailers: [
      "Amazon UK",
      "Currys",
      "Argos",
      "John Lewis",
      "Very",
      "AO.com",
    ],
    amazonDomain: "amazon.co.uk",
    searchUrls: {
      "amazon uk": (q) => `https://www.amazon.co.uk/s?k=${encodeURIComponent(q)}`,
      amazon: (q) => `https://www.amazon.co.uk/s?k=${encodeURIComponent(q)}`,
      currys: (q) => `https://www.currys.co.uk/search/${encodeURIComponent(q)}`,
      argos: (q) => `https://www.argos.co.uk/search/${encodeURIComponent(q)}`,
      "john lewis": (q) => `https://www.johnlewis.com/search?search-term=${encodeURIComponent(q)}`,
      very: (q) => `https://www.very.co.uk/search/${encodeURIComponent(q)}`,
      "ao.com": (q) => `https://ao.com/search?q=${encodeURIComponent(q)}`,
    },
  },

  DE: {
    code: "DE",
    name: "Germany",
    currency: "EUR",
    currencySymbol: "€",
    locale: "de-DE",
    retailers: [
      "Amazon Germany",
      "MediaMarkt",
      "Saturn",
      "Otto",
      "Cyberport",
      "Alternate",
    ],
    amazonDomain: "amazon.de",
    searchUrls: {
      "amazon germany": (q) => `https://www.amazon.de/s?k=${encodeURIComponent(q)}`,
      amazon: (q) => `https://www.amazon.de/s?k=${encodeURIComponent(q)}`,
      mediamarkt: (q) => `https://www.mediamarkt.de/de/search.html?query=${encodeURIComponent(q)}`,
      saturn: (q) => `https://www.saturn.de/de/search.html?query=${encodeURIComponent(q)}`,
      otto: (q) => `https://www.otto.de/suche/${encodeURIComponent(q)}`,
      cyberport: (q) => `https://www.cyberport.de/?q=${encodeURIComponent(q)}`,
      alternate: (q) => `https://www.alternate.de/listing.xhtml?q=${encodeURIComponent(q)}`,
    },
  },

  CA: {
    code: "CA",
    name: "Canada",
    currency: "CAD",
    currencySymbol: "CA$",
    locale: "en-CA",
    retailers: [
      "Amazon Canada",
      "Best Buy Canada",
      "Walmart Canada",
      "Canada Computers",
      "The Source",
    ],
    amazonDomain: "amazon.ca",
    searchUrls: {
      "amazon canada": (q) => `https://www.amazon.ca/s?k=${encodeURIComponent(q)}`,
      amazon: (q) => `https://www.amazon.ca/s?k=${encodeURIComponent(q)}`,
      "best buy canada": (q) => `https://www.bestbuy.ca/en-ca/search?search=${encodeURIComponent(q)}`,
      "best buy": (q) => `https://www.bestbuy.ca/en-ca/search?search=${encodeURIComponent(q)}`,
      "walmart canada": (q) => `https://www.walmart.ca/search?q=${encodeURIComponent(q)}`,
      walmart: (q) => `https://www.walmart.ca/search?q=${encodeURIComponent(q)}`,
      "canada computers": (q) => `https://www.canadacomputers.com/search/results_details.php?keywords=${encodeURIComponent(q)}`,
      "the source": (q) => `https://www.thesource.ca/en-ca/search?text=${encodeURIComponent(q)}`,
    },
  },

  AU: {
    code: "AU",
    name: "Australia",
    currency: "AUD",
    currencySymbol: "A$",
    locale: "en-AU",
    retailers: [
      "Amazon Australia",
      "JB Hi-Fi",
      "Harvey Norman",
      "The Good Guys",
      "Officeworks",
      "Kogan",
    ],
    amazonDomain: "amazon.com.au",
    searchUrls: {
      "amazon australia": (q) => `https://www.amazon.com.au/s?k=${encodeURIComponent(q)}`,
      amazon: (q) => `https://www.amazon.com.au/s?k=${encodeURIComponent(q)}`,
      "jb hi-fi": (q) => `https://www.jbhifi.com.au/search?page=1&query=${encodeURIComponent(q)}`,
      "jb hifi": (q) => `https://www.jbhifi.com.au/search?page=1&query=${encodeURIComponent(q)}`,
      "harvey norman": (q) => `https://www.harveynorman.com.au/search?q=${encodeURIComponent(q)}`,
      "the good guys": (q) => `https://www.thegoodguys.com.au/SearchDisplay?searchTerm=${encodeURIComponent(q)}`,
      officeworks: (q) => `https://www.officeworks.com.au/shop/officeworks/search?q=${encodeURIComponent(q)}`,
      kogan: (q) => `https://www.kogan.com/au/shop/?q=${encodeURIComponent(q)}`,
    },
  },

  JP: {
    code: "JP",
    name: "Japan",
    currency: "JPY",
    currencySymbol: "¥",
    locale: "ja-JP",
    retailers: [
      "Amazon Japan",
      "Yodobashi Camera",
      "Bic Camera",
      "Kakaku.com",
      "Rakuten",
    ],
    amazonDomain: "amazon.co.jp",
    searchUrls: {
      "amazon japan": (q) => `https://www.amazon.co.jp/s?k=${encodeURIComponent(q)}`,
      amazon: (q) => `https://www.amazon.co.jp/s?k=${encodeURIComponent(q)}`,
      "yodobashi camera": (q) => `https://www.yodobashi.com/?word=${encodeURIComponent(q)}`,
      yodobashi: (q) => `https://www.yodobashi.com/?word=${encodeURIComponent(q)}`,
      "bic camera": (q) => `https://www.biccamera.com/bc/category/?q=${encodeURIComponent(q)}`,
      rakuten: (q) => `https://search.rakuten.co.jp/search/mall/${encodeURIComponent(q)}`,
    },
  },

  FR: {
    code: "FR",
    name: "France",
    currency: "EUR",
    currencySymbol: "€",
    locale: "fr-FR",
    retailers: ["Amazon France", "Fnac", "Darty", "Boulanger", "Cdiscount"],
    amazonDomain: "amazon.fr",
    searchUrls: {
      "amazon france": (q) => `https://www.amazon.fr/s?k=${encodeURIComponent(q)}`,
      amazon: (q) => `https://www.amazon.fr/s?k=${encodeURIComponent(q)}`,
      fnac: (q) => `https://www.fnac.com/SearchResult/ResultList.aspx?Search=${encodeURIComponent(q)}`,
      darty: (q) => `https://www.darty.com/nav/recherche?text=${encodeURIComponent(q)}`,
      boulanger: (q) => `https://www.boulanger.com/resultats?tr=${encodeURIComponent(q)}`,
      cdiscount: (q) => `https://www.cdiscount.com/search/10/${encodeURIComponent(q)}.html`,
    },
  },
};

// Aliases
REGIONS["GB"] = REGIONS["UK"];

const DEFAULT_REGION = "US";

export function getRegionConfig(region?: string): RegionConfig {
  if (!region) return REGIONS[DEFAULT_REGION];
  const code = region.toUpperCase().trim();
  return REGIONS[code] || REGIONS[DEFAULT_REGION];
}

export function getSupportedRegions(): string[] {
  return Object.keys(REGIONS).filter((k) => k !== "GB"); // exclude alias
}

/**
 * Format a price for a region.
 */
export function formatPrice(price: number, region: RegionConfig): string {
  return `${region.currencySymbol}${price.toLocaleString(region.locale)}`;
}

/**
 * Check if a retailer is in our curated trusted list for a region.
 * Fuzzy matches against region retailers + searchUrls keys.
 */
/**
 * Get retailer name → domain mapping for a region.
 * Used to make Perplexity actually check each retailer's website.
 */
export function getRetailerDomains(region: RegionConfig): string {
  // Extract domains from searchUrls — deduplicate by retailer name
  const seen = new Set<string>();
  const pairs: string[] = [];
  for (const [key, fn] of Object.entries(region.searchUrls)) {
    const name = region.retailers.find((r) => r.toLowerCase() === key || r.toLowerCase().includes(key) || key.includes(r.toLowerCase()));
    const displayName = name || key;
    if (seen.has(displayName.toLowerCase())) continue;
    seen.add(displayName.toLowerCase());
    // Extract domain from the URL builder
    try {
      const url = fn("test");
      const domain = new URL(url).hostname.replace("www.", "");
      pairs.push(`${displayName} (${domain})`);
    } catch {
      pairs.push(displayName);
    }
  }
  return pairs.join(", ");
}

export function isTrustedRetailer(retailer: string, region: RegionConfig): boolean {
  const key = retailer.toLowerCase().trim();
  // Check against retailer list
  if (region.retailers.some((r) => {
    const rk = r.toLowerCase();
    return rk === key || rk.includes(key) || key.includes(rk);
  })) return true;
  // Check against searchUrls keys (includes aliases like "bestbuy", "jb hifi")
  if (Object.keys(region.searchUrls).some((k) => k === key || k.includes(key) || key.includes(k))) return true;
  // Also trust manufacturer stores
  const manufacturers = ["apple store", "apple", "samsung store", "samsung", "google store", "google",
    "sony store", "sony", "microsoft store", "microsoft", "oneplus", "dell", "lenovo", "hp store",
    "dyson", "bose", "nintendo", "playstation"];
  if (manufacturers.some((m) => key.includes(m) || m.includes(key))) return true;
  return false;
}

/**
 * Build a search URL for a retailer in a given region.
 * Falls back to Google search if retailer not recognized.
 */
export function getRetailerSearchUrl(
  retailer: string,
  productName: string,
  region: RegionConfig
): string {
  const key = retailer.toLowerCase();
  const urlBuilder =
    region.searchUrls[key] ||
    Object.entries(region.searchUrls).find(([k]) => key.includes(k))?.[1];

  if (urlBuilder) return urlBuilder(productName);
  return `https://www.google.com/search?q=${encodeURIComponent(productName + " " + retailer + " buy")}`;
}
