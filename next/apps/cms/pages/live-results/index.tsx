import Head from 'next/head';
import Link from 'next/link';
import { useRouter } from 'next/router';
import { useEffect } from 'react';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { isSupabaseConfigured } from '../../core/live-results/supabase-client';
import { useEvents } from '../../core/live-results/use-live-results';

// Lists every event in race-timing's Supabase project, newest first; each
// links through to /live-results/[eventId] for that event's leaderboard.
export default function LiveResultsListPage() {
  const router = useRouter();
  const { data: events, isLoading, error } = useEvents();

  // Keep old ?event=<id> links working.
  useEffect(() => {
    if (router.isReady && typeof router.query.event === 'string') {
      router.replace(`/live-results/${encodeURIComponent(router.query.event)}`);
    }
  }, [router]);

  return (
    <>
      <Head>
        <title>Live Results | Black Pear Joggers</title>
      </Head>

      <Stack backgroundColour={BackgroundColour.White}>
        <Container wide>
          <h1>Live Results</h1>

          {!isSupabaseConfigured && <p>Live results aren&rsquo;t configured for this site yet.</p>}
          {isSupabaseConfigured && isLoading && <p>Loading events&hellip;</p>}
          {isSupabaseConfigured && error && (
            <p>Couldn&rsquo;t load events right now &mdash; this page retries automatically.</p>
          )}
          {isSupabaseConfigured && !isLoading && !error && events?.length === 0 && (
            <p>No events yet. Results will appear here once a race goes live in the timing app.</p>
          )}

          {events && events.length > 0 && (
            <ul className="list-none p-0">
              {events.map((event) => (
                <li key={event.id} className="border-b border-gray-200 py-3">
                  <Link href={`/live-results/${encodeURIComponent(event.id)}`} className="text-lg font-bold">
                    {event.name}
                  </Link>
                  <div className="text-sm text-gray-600">
                    {new Date(event.date).toLocaleDateString('en-GB', { dateStyle: 'long' })}
                    {event.location && <> &middot; {event.location}</>}
                    {' '}&middot;{' '}
                    {event.status === 'active' ? 'Live' : event.status}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Container>
      </Stack>
    </>
  );
}
