# Database Migrations

## Running Migrations

These SQL files should be run directly in the Supabase SQL Editor:

1. Go to https://supabase.com/dashboard/project/zamecftkxpgkjqtbanmt/sql/new
2. Copy the contents of the migration file
3. Paste into the SQL editor
4. Click "Run"

## Migration Files

- `001_price_history.sql` - Creates the `price_history` table for storing historical price data from product searches

## Notes

- Migrations are idempotent (safe to re-run)
- RLS is enabled but service role has full access
- Indexes are optimized for common query patterns (product+region lookups, date filtering)
