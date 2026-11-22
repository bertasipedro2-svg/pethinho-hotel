import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// Reuse the same browser client for auth listeners and database queries.
// Creating a new client on each call can duplicate session listeners and
// cause auth changes to be observed by a different instance than the UI uses.
let browserClient: SupabaseClient | undefined;

export function getSupabase(): SupabaseClient {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) throw new Error("Supabase não configurado");

  if (typeof window === "undefined") {
    // Never share an authenticated client across server requests.
    return createClient(url, key);
  }

  browserClient ??= createClient(url, key);
  return browserClient;
}
