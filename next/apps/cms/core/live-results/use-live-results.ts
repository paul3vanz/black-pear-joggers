import { useQuery } from '@tanstack/react-query';
import { fetchLiveResults } from './queries';
import { isSupabaseConfigured } from './supabase-client';

const REFRESH_INTERVAL_MS = 10_000;

// eventId is an explicit ?event= override (e.g. linking to a specific past
// event) — omit it to auto-follow whatever's currently live.
export function useLiveResults(eventId?: string) {
  return useQuery(['live-results', eventId ?? 'auto'], () => fetchLiveResults(eventId), {
    enabled: isSupabaseConfigured,
    refetchInterval: REFRESH_INTERVAL_MS,
    refetchIntervalInBackground: false,
  });
}
