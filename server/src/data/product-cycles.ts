/**
 * Product release cycles for major brands.
 * Used to predict upcoming launches and depreciation of current models.
 */

export interface ProductCycle {
  brand: string;
  productLine: string;
  typicalLaunchMonth: number; // 1-12
  announcementOffset: string; // e.g. "2 weeks before launch"
  priceDropAfterNew: string; // typical % drop on old model
  keywords: string[]; // for matching user queries
}

export const PRODUCT_CYCLES: ProductCycle[] = [
  // Apple
  {
    brand: "Apple",
    productLine: "iPhone",
    typicalLaunchMonth: 9,
    announcementOffset: "Early September event",
    priceDropAfterNew: "15-25% within 2 months",
    keywords: ["iphone"],
  },
  {
    brand: "Apple",
    productLine: "MacBook Pro",
    typicalLaunchMonth: 10,
    announcementOffset: "October or November event",
    priceDropAfterNew: "10-20% on previous gen",
    keywords: ["macbook pro"],
  },
  {
    brand: "Apple",
    productLine: "MacBook Air",
    typicalLaunchMonth: 3,
    announcementOffset: "March event or WWDC",
    priceDropAfterNew: "10-15% on previous gen",
    keywords: ["macbook air"],
  },
  {
    brand: "Apple",
    productLine: "iPad",
    typicalLaunchMonth: 3,
    announcementOffset: "March-May event",
    priceDropAfterNew: "15-25% on previous gen",
    keywords: ["ipad"],
  },
  {
    brand: "Apple",
    productLine: "Apple Watch",
    typicalLaunchMonth: 9,
    announcementOffset: "September event with iPhone",
    priceDropAfterNew: "20-30% on previous gen",
    keywords: ["apple watch"],
  },
  {
    brand: "Apple",
    productLine: "AirPods",
    typicalLaunchMonth: 9,
    announcementOffset: "September event, every 2 years",
    priceDropAfterNew: "15-20% on previous gen",
    keywords: ["airpods"],
  },

  // Samsung
  {
    brand: "Samsung",
    productLine: "Galaxy S",
    typicalLaunchMonth: 1,
    announcementOffset: "January Unpacked event",
    priceDropAfterNew: "20-30% within 3 months",
    keywords: ["galaxy s", "samsung s"],
  },
  {
    brand: "Samsung",
    productLine: "Galaxy Fold/Flip",
    typicalLaunchMonth: 7,
    announcementOffset: "July Unpacked event",
    priceDropAfterNew: "25-35% within 3 months",
    keywords: ["galaxy fold", "galaxy flip", "galaxy z"],
  },
  {
    brand: "Samsung",
    productLine: "Galaxy A (mid-range)",
    typicalLaunchMonth: 3,
    announcementOffset: "March-April",
    priceDropAfterNew: "10-20%",
    keywords: ["galaxy a"],
  },

  // Google
  {
    brand: "Google",
    productLine: "Pixel",
    typicalLaunchMonth: 10,
    announcementOffset: "October Made by Google event",
    priceDropAfterNew: "20-30% on previous gen",
    keywords: ["pixel"],
  },
  {
    brand: "Google",
    productLine: "Pixel A",
    typicalLaunchMonth: 5,
    announcementOffset: "Google I/O (May)",
    priceDropAfterNew: "15-20%",
    keywords: ["pixel a"],
  },

  // OnePlus
  {
    brand: "OnePlus",
    productLine: "OnePlus (flagship)",
    typicalLaunchMonth: 3,
    announcementOffset: "March launch event",
    priceDropAfterNew: "15-25%",
    keywords: ["oneplus"],
  },
  {
    brand: "OnePlus",
    productLine: "OnePlus T/Pro",
    typicalLaunchMonth: 8,
    announcementOffset: "August-September",
    priceDropAfterNew: "15-20%",
    keywords: ["oneplus"],
  },

  // Sony
  {
    brand: "Sony",
    productLine: "PlayStation",
    typicalLaunchMonth: 11,
    announcementOffset: "Varies (E3/TGS)",
    priceDropAfterNew: "Price cuts announced at events",
    keywords: ["playstation", "ps5", "ps6"],
  },

  // Microsoft
  {
    brand: "Microsoft",
    productLine: "Xbox",
    typicalLaunchMonth: 11,
    announcementOffset: "Xbox Showcase (June)",
    priceDropAfterNew: "Holiday bundles common",
    keywords: ["xbox"],
  },

  // Laptops
  {
    brand: "Lenovo",
    productLine: "ThinkPad/IdeaPad",
    typicalLaunchMonth: 1,
    announcementOffset: "CES (January)",
    priceDropAfterNew: "10-20% on previous gen",
    keywords: ["thinkpad", "ideapad", "lenovo"],
  },
  {
    brand: "Dell",
    productLine: "XPS/Inspiron",
    typicalLaunchMonth: 1,
    announcementOffset: "CES (January)",
    priceDropAfterNew: "10-20% on previous gen",
    keywords: ["xps", "dell", "inspiron"],
  },
  {
    brand: "ASUS",
    productLine: "ROG/ZenBook",
    typicalLaunchMonth: 1,
    announcementOffset: "CES (January) + Computex (May)",
    priceDropAfterNew: "15-25% on previous gen",
    keywords: ["rog", "zenbook", "asus"],
  },
];

/**
 * Find matching product cycle for a search query.
 */
export function findProductCycle(query: string): ProductCycle | null {
  const q = query.toLowerCase();
  return PRODUCT_CYCLES.find((cycle) =>
    cycle.keywords.some((kw) => q.includes(kw))
  ) || null;
}
