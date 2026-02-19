/**
 * Global e-commerce sale calendar.
 * Region-aware — each event specifies which regions it applies to.
 */

export interface SaleEvent {
  name: string;
  retailer: string;
  typicalMonth: number; // 1-12
  typicalDuration: string;
  avgDiscount: string;
  categories: string[];
  regions: string[]; // which region codes this applies to ("ALL" = global)
}

export const SALE_CALENDAR: SaleEvent[] = [
  // ===== GLOBAL =====
  {
    name: "Black Friday / Cyber Monday",
    retailer: "All",
    typicalMonth: 11,
    typicalDuration: "4-7 days",
    avgDiscount: "15-50% on electronics, 30-60% on fashion",
    categories: ["smartphones", "laptops", "electronics", "gaming", "fashion", "home"],
    regions: ["ALL"],
  },
  {
    name: "New Year Sales",
    retailer: "All",
    typicalMonth: 12,
    typicalDuration: "7-14 days",
    avgDiscount: "10-30% end-of-year clearance",
    categories: ["electronics", "fashion", "home"],
    regions: ["ALL"],
  },

  // ===== INDIA =====
  {
    name: "Amazon Great Republic Day Sale",
    retailer: "Amazon India",
    typicalMonth: 1,
    typicalDuration: "5-7 days",
    avgDiscount: "10-40% on electronics, 30-60% on fashion",
    categories: ["smartphones", "laptops", "electronics", "fashion"],
    regions: ["IN"],
  },
  {
    name: "Flipkart Republic Day Sale",
    retailer: "Flipkart",
    typicalMonth: 1,
    typicalDuration: "5-7 days",
    avgDiscount: "10-40% on electronics",
    categories: ["smartphones", "laptops", "electronics", "fashion"],
    regions: ["IN"],
  },
  {
    name: "Flipkart Big Saving Days",
    retailer: "Flipkart",
    typicalMonth: 5,
    typicalDuration: "5-6 days",
    avgDiscount: "15-35% on electronics",
    categories: ["smartphones", "laptops", "electronics"],
    regions: ["IN"],
  },
  {
    name: "Amazon Prime Day",
    retailer: "Amazon",
    typicalMonth: 7,
    typicalDuration: "2-3 days",
    avgDiscount: "15-40% on electronics, exclusive Prime deals",
    categories: ["smartphones", "laptops", "electronics", "home"],
    regions: ["IN", "US", "UK", "DE", "CA", "AU", "FR", "JP"],
  },
  {
    name: "Flipkart Big Billion Days",
    retailer: "Flipkart",
    typicalMonth: 10,
    typicalDuration: "7-10 days",
    avgDiscount: "20-50% — biggest Flipkart sale",
    categories: ["smartphones", "laptops", "electronics", "home", "fashion"],
    regions: ["IN"],
  },
  {
    name: "Amazon Great Indian Festival",
    retailer: "Amazon India",
    typicalMonth: 10,
    typicalDuration: "7-10 days",
    avgDiscount: "20-50% — biggest sale of the year",
    categories: ["smartphones", "laptops", "electronics", "home", "fashion"],
    regions: ["IN"],
  },
  {
    name: "Diwali Sales (multi-retailer)",
    retailer: "All",
    typicalMonth: 11,
    typicalDuration: "2-3 weeks",
    avgDiscount: "15-40% across categories",
    categories: ["electronics", "home", "fashion"],
    regions: ["IN"],
  },

  // ===== US =====
  {
    name: "Presidents' Day Sales",
    retailer: "All",
    typicalMonth: 2,
    typicalDuration: "3-5 days",
    avgDiscount: "10-30% on appliances, TVs, mattresses",
    categories: ["electronics", "home", "appliances"],
    regions: ["US"],
  },
  {
    name: "Memorial Day Sales",
    retailer: "All",
    typicalMonth: 5,
    typicalDuration: "4-7 days",
    avgDiscount: "15-40% on appliances, outdoor, electronics",
    categories: ["home", "appliances", "electronics", "outdoor"],
    regions: ["US"],
  },
  {
    name: "4th of July Sales",
    retailer: "All",
    typicalMonth: 7,
    typicalDuration: "3-5 days",
    avgDiscount: "10-25% on electronics",
    categories: ["electronics", "home", "outdoor"],
    regions: ["US"],
  },
  {
    name: "Labor Day Sales",
    retailer: "All",
    typicalMonth: 9,
    typicalDuration: "4-7 days",
    avgDiscount: "15-35% on electronics, appliances",
    categories: ["electronics", "appliances", "home"],
    regions: ["US"],
  },

  // ===== UK =====
  {
    name: "Boxing Day Sales",
    retailer: "All",
    typicalMonth: 12,
    typicalDuration: "5-10 days",
    avgDiscount: "20-50% across categories",
    categories: ["electronics", "fashion", "home", "gaming"],
    regions: ["UK", "CA", "AU"],
  },
  {
    name: "January Sales",
    retailer: "All",
    typicalMonth: 1,
    typicalDuration: "2-4 weeks",
    avgDiscount: "20-50% clearance",
    categories: ["electronics", "fashion", "home"],
    regions: ["UK"],
  },
  {
    name: "Bank Holiday Sales",
    retailer: "All",
    typicalMonth: 5,
    typicalDuration: "3-4 days",
    avgDiscount: "10-30%",
    categories: ["electronics", "home", "fashion"],
    regions: ["UK"],
  },

  // ===== GERMANY / EU =====
  {
    name: "Winterschlussverkauf (Winter Sale)",
    retailer: "All",
    typicalMonth: 1,
    typicalDuration: "2-4 weeks",
    avgDiscount: "20-50% clearance",
    categories: ["fashion", "electronics", "home"],
    regions: ["DE", "FR"],
  },
  {
    name: "Sommerschlussverkauf (Summer Sale)",
    retailer: "All",
    typicalMonth: 7,
    typicalDuration: "2-4 weeks",
    avgDiscount: "20-50% clearance",
    categories: ["fashion", "electronics", "home"],
    regions: ["DE", "FR"],
  },

  // ===== JAPAN =====
  {
    name: "New Year Fukubukuro Sales",
    retailer: "All",
    typicalMonth: 1,
    typicalDuration: "1-2 weeks",
    avgDiscount: "30-60% mystery bags + clearance",
    categories: ["electronics", "fashion", "home"],
    regions: ["JP"],
  },
  {
    name: "Golden Week Sales",
    retailer: "All",
    typicalMonth: 5,
    typicalDuration: "7-10 days",
    avgDiscount: "10-30%",
    categories: ["electronics", "fashion", "home"],
    regions: ["JP"],
  },

  // ===== AUSTRALIA =====
  {
    name: "EOFY Sales (End of Financial Year)",
    retailer: "All",
    typicalMonth: 6,
    typicalDuration: "2-3 weeks",
    avgDiscount: "20-50% tax-time clearance",
    categories: ["electronics", "laptops", "home", "appliances"],
    regions: ["AU"],
  },
  {
    name: "Click Frenzy",
    retailer: "All",
    typicalMonth: 11,
    typicalDuration: "2-3 days",
    avgDiscount: "15-40% on electronics",
    categories: ["electronics", "fashion", "home"],
    regions: ["AU"],
  },
];

/**
 * Find the next upcoming sale event for a given region.
 */
export function getNextSaleEvent(currentMonth: number, region?: string): SaleEvent | null {
  const regionCode = (region || "US").toUpperCase();

  // Filter to events relevant for this region
  const regionEvents = SALE_CALENDAR.filter(
    (s) => s.regions.includes("ALL") || s.regions.includes(regionCode)
  );

  const sorted = [...regionEvents].sort((a, b) => {
    const distA = (a.typicalMonth - currentMonth + 12) % 12;
    const distB = (b.typicalMonth - currentMonth + 12) % 12;
    return distA - distB;
  });

  return sorted.find((s) => {
    const dist = (s.typicalMonth - currentMonth + 12) % 12;
    return dist > 0 && dist <= 3;
  }) || null;
}
