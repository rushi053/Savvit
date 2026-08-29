/**
 * Simple in-memory rate limiter.
 * For MVP — replace with Redis at scale.
 */

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const store = new Map<string, RateLimitEntry>();

// Clean up expired entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of store) {
    if (now > entry.resetAt) store.delete(key);
  }
}, 5 * 60 * 1000);

export interface RateLimitConfig {
  windowMs: number;   // time window in ms
  maxRequests: number; // max requests per window
}

export const RATE_LIMITS = {
  // 25/hour: leaves headroom for the iOS watchlist auto-refresh (up to 6
  // requests per pass) on top of manual searches. Most refreshes hit the
  // server-side price cache, so the real API cost stays low.
  ANONYMOUS: { windowMs: 60 * 60 * 1000, maxRequests: 25 },     // 25/hour
  AUTHENTICATED: { windowMs: 60 * 60 * 1000, maxRequests: 40 }, // 40/hour
  PRO: { windowMs: 60 * 60 * 1000, maxRequests: 100 },          // 100/hour
};

/**
 * Check rate limit for a key. Returns { allowed, remaining, retryAfter }.
 */
export function checkRateLimit(
  key: string,
  config: RateLimitConfig
): { allowed: boolean; remaining: number; retryAfterMs: number } {
  const now = Date.now();
  let entry = store.get(key);

  if (!entry || now > entry.resetAt) {
    entry = { count: 0, resetAt: now + config.windowMs };
    store.set(key, entry);
  }

  entry.count++;

  if (entry.count > config.maxRequests) {
    return {
      allowed: false,
      remaining: 0,
      retryAfterMs: entry.resetAt - now,
    };
  }

  return {
    allowed: true,
    remaining: config.maxRequests - entry.count,
    retryAfterMs: 0,
  };
}
