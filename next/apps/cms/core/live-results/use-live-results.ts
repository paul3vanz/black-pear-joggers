import { useQuery } from '@tanstack/react-query';
import { fetchEvents, fetchLiveResults } from './queries';
import { isSupabaseConfigured } from './supabase-client';

const REFRESH_INTERVAL_MS = 10_000;

export function useEvents() {
  return useQuery(['live-results-events'], fetchEvents, {
    enabled: isSupabaseConfigured,
    refetchInterval: REFRESH_INTERVAL_MS,
    refetchIntervalInBackground: false,
  });
}

export function useLiveResults(eventId?: string) {
  return useQuery(['live-results', eventId], () => fetchLiveResults(eventId as string), {
    enabled: isSupabaseConfigured && !!eventId,
    refetchInterval: REFRESH_INTERVAL_MS,
    refetchIntervalInBackground: false,
  });
}
