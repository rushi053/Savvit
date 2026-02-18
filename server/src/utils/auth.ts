import { Context, Next } from "hono";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL || "";
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || "";

export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

/**
 * Auth middleware — validates Supabase JWT or API bearer token.
 * For MVP, supports both:
 * 1. Supabase Auth JWT (from iOS app after sign-in)
 * 2. Static API bearer token (for testing/development)
 */
export async function authMiddleware(c: Context, next: Next) {
  const authHeader = c.req.header("Authorization");

  if (!authHeader?.startsWith("Bearer ")) {
    return c.json({ error: "Missing authorization header" }, 401);
  }

  const token = authHeader.slice(7);

  // Check static API token first (dev/testing)
  if (token === process.env.API_BEARER_TOKEN) {
    c.set("userId", "dev-user");
    return next();
  }

  // Validate Supabase JWT
  try {
    const { data, error } = await supabaseAdmin.auth.getUser(token);
    if (error || !data.user) {
      return c.json({ error: "Invalid or expired token" }, 401);
    }
    c.set("userId", data.user.id);
    return next();
  } catch {
    return c.json({ error: "Authentication failed" }, 401);
  }
}
