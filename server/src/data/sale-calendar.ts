/**
 * Indian e-commerce sale calendar.
 * Hardcoded for MVP — update periodically.
 */

export interface SaleEvent {
  name: string;
  retailer: string;
  typicalMonth: number; // 1-12
  typicalDuration: string;
  avgDiscount: string;
  categories: string[]; // which product categories see best deals
}

export const SALE_CALENDAR: SaleEvent[] = [
  // Amazon India
  {
    name: "Amazon Great Republic Day Sale",
    retailer: "Amazon India",
    typicalMonth: 1,
    typicalDuration: "5-7 days",
    avgDiscount: "10-40% on electronics, 30-60% on fashion",
    categories: ["smartphones", "laptops", "electronics", "fashion"],
  },
  {
    name: "Amazon Prime Day",
    retailer: "Amazon India",
    typicalMonth: 7,
    typicalDuration: "2-3 days",
    avgDiscount: "15-40% on electronics, exclusive Prime deals",
    categories: ["smartphones", "laptops", "electronics", "home"],
  },
  {
    name: "Amazon Great Indian Festival",
    retailer: "Amazon India",
    typicalMonth: 10,
    typicalDuration: "7-10 days",
    avgDiscount: "20-50% — biggest sale of the year",
    categories: ["smartphones", "laptops", "electronics", "home", "fashion"],
  },

  // Flipkart
  {
    name: "Flipkart Republic Day Sale",
    retailer: "Flipkart",
    typicalMonth: 1,
    typicalDuration: "5-7 days",
    avgDiscount: "10-40% on electronics",
    categories: ["smartphones", "laptops", "electronics", "fashion"],
  },
  {
    name: "Flipkart Big Saving Days",
    retailer: "Flipkart",
    typicalMonth: 5,
    typicalDuration: "5-6 days",
    avgDiscount: "15-35% on electronics",
    categories: ["smartphones", "laptops", "electronics"],
  },
  {
    name: "Flipkart Big Billion Days",
    retailer: "Flipkart",
    typicalMonth: 10,
    typicalDuration: "7-10 days",
    avgDiscount: "20-50% — biggest Flipkart sale",
    categories: ["smartphones", "laptops", "electronics", "home", "fashion"],
  },

  // General
  {
    name: "Diwali Sales (multi-retailer)",
    retailer: "All",
    typicalMonth: 11,
    typicalDuration: "2-3 weeks",
    avgDiscount: "15-40% across categories",
    categories: ["electronics", "home", "fashion"],
  },
  {
    name: "Black Friday / Cyber Monday",
    retailer: "All",
    typicalMonth: 11,
    typicalDuration: "4-5 days",
    avgDiscount: "15-50% (especially on global brands)",
    categories: ["laptops", "electronics", "software", "gaming"],
  },
  {
    name: "New Year Sales",
    retailer: "All",
    typicalMonth: 12,
    typicalDuration: "7-10 days",
    avgDiscount: "10-30% end-of-year clearance",
    categories: ["electronics", "fashion", "home"],
  },
];

/**
 * Find the next upcoming sale event.
 */
export function getNextSaleEvent(currentMonth: number): SaleEvent | null {
  // Sort by how soon the sale is from current month
  const sorted = [...SALE_CALENDAR].sort((a, b) => {
    const distA = (a.typicalMonth - currentMonth + 12) % 12;
    const distB = (b.typicalMonth - currentMonth + 12) % 12;
    return distA - distB;
  });

  // Return the nearest future sale (skip current month if past mid-month)
  return sorted.find((s) => {
    const dist = (s.typicalMonth - currentMonth + 12) % 12;
    return dist > 0 && dist <= 3; // Within next 3 months
  }) || null;
}
