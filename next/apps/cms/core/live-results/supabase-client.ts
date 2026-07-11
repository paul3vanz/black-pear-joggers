import { createClient } from '@supabase/supabase-js';

// Read-only viewer for the race-timing app's Supabase project. This is
// literally the same anon key race-timing's mobile app uses (found the same
// place: Supabase dashboard > Project Settings > API) — it's safe to expose
// here specifically because RLS now scopes `anon` to SELECT-only on every
// table, with writes requiring an `authenticated` session the mobile app
// gets via Supabase's built-in anonymous sign-in instead. See:
//   race-timing/supabase/migrations/20260711130000_anon_read_only_split.sql
//   race-timing/lib/supabase.ts (ensureAnonymousSession)
//
// (An earlier attempt used a separate hand-signed key for a dedicated
// Postgres role — abandoned because Supabase's hosted API gateway only
// accepts registered keys, so that role was unreachable regardless of RLS.)
//
// NEXT_PUBLIC_* vars are inlined at build time, so this must be set in the
// Cloudflare Pages build config, not a local .env this repo doesn't
// otherwise use.
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseReadonlyKey = process.env.NEXT_PUBLIC_SUPABASE_READONLY_KEY;

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseReadonlyKey);

export const supabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseReadonlyKey || 'placeholder-readonly-key',
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  }
);
