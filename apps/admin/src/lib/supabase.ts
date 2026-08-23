import { createClient, SupabaseClient } from '@supabase/supabase-js';

let client: SupabaseClient | null = null;

/**
 * Get the Supabase client (lazy singleton).
 * Returns null if credentials are not configured.
 */
export function getSupabase(): SupabaseClient | null {
  if (!client) {
    const url = process.env.SUPABASE_URL;
    const serviceKey = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_KEY;

    if (!url || !serviceKey) {
      console.warn('Missing Supabase credentials. Set SUPABASE_URL and SUPABASE_SECRET_KEY.');
      return null;
    }

    client = createClient(url, serviceKey);
  }
  return client;
}

/**
 * Check if Supabase is configured
 */
export function isSupabaseConfigured(): boolean {
  return !!(process.env.SUPABASE_URL && (process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_KEY));
}
