/**
 * Simple in-memory cache with TTL.
 * For MVP — replace with Redis/Supabase cache at scale.
 */

interface CacheEntry<T> {
  data: T;
  expiresAt: number;
}

const store = new Map<string, CacheEntry<unknown>>();

export function getCached<T>(key: string): T | null {
  const entry = store.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    store.delete(key);
    return null;
  }
  return entry.data as T;
}

export function setCache<T>(key: string, data: T, ttlMs: number): void {
  store.set(key, { data, expiresAt: Date.now() + ttlMs });
}

// Cache TTLs
export const CACHE_TTL = {
  PRICES: 6 * 60 * 60 * 1000,        // 6 hours
  VERDICT: 12 * 60 * 60 * 1000,      // 12 hours
  LAUNCH_NEWS: 7 * 24 * 60 * 60 * 1000, // 7 days
  KEEPA_HISTORY: 24 * 60 * 60 * 1000,   // 24 hours
};
