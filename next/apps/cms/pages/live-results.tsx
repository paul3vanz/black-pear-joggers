import Head from 'next/head';
import { useRouter } from 'next/router';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { formatElapsed, formatOrdinal, sortCategoryKeys } from '../core/live-results/leaderboard';
import { isSupabaseConfigured } from '../core/live-results/supabase-client';
import { useLiveResults } from '../core/live-results/use-live-results';
import { LeaderboardEntry } from '../core/live-results/types';

const thClass = 'border-b-2 border-gray-300 p-2 font-bold whitespace-nowrap';
const tdClass = 'border-b border-gray-200 p-2 whitespace-nowrap';

// Static, fully client-rendered page (this app is exported to Cloudflare
// Pages — see next.config.js `output: 'export'`) that polls race-timing's
// Supabase project directly for in-flight lapped-race results. Requires
// NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_READONLY_KEY to be set in
// the Cloudflare Pages build config — see core/live-results/supabase-client.ts
// for why this key can only ever read, despite being public in this page's
// JS bundle.
export default function LiveResultsPage() {
  const router = useRouter();
  const eventId = typeof router.query.event === 'string' ? router.query.event : undefined;
  const { data, isLoading, error } = useLiveResults(eventId);

  const totalFinishers = data
    ? Object.values(data.leaderboardByCategory).reduce((sum, entries) => sum + entries.length, 0)
    : 0;

  return (
    <>
      <Head>
        <title>Live Results | Black Pear Joggers</title>
      </Head>

      <Stack backgroundColour={BackgroundColour.White}>
        <Container wide>
          <h1>Live Results</h1>

          {!isSupabaseConfigured && (
            <p>Live results aren&rsquo;t configured for this site yet.</p>
          )}

          {isSupabaseConfigured && isLoading && <p>Loading live results&hellip;</p>}

          {isSupabaseConfigured && error && (
            <p>Couldn&rsquo;t load live results right now &mdash; this page retries automatically.</p>
          )}

          {isSupabaseConfigured && !isLoading && !error && !data?.event && (
            <p>No event found yet. Results will appear here once a race goes live in the timing app.</p>
          )}

          {data?.event && (
            <>
              <p className="text-lg">
                <strong>{data.event.name}</strong>
                {' '}&middot;{' '}
                {data.event.status === 'active' ? 'Live' : data.event.status}
                {' '}&middot;{' '}
                {totalFinishers} finisher{totalFinishers === 1 ? '' : 's'} recording results
              </p>

              {Object.keys(data.leaderboardByCategory).length === 0 ? (
                <p>No finishers recorded yet &mdash; check back once the first laps come in.</p>
              ) : (
                sortCategoryKeys(Object.keys(data.leaderboardByCategory)).map((category) => {
                  const entries = data.leaderboardByCategory[category];
                  const hasGender = entries.some((entry) => entry.gender);
                  const hasCategory = entries.some((entry) => entry.category);
                  const maxLaps = Math.max(0, ...entries.map((entry) => entry.lapsCompleted));
                  const lapColumns = Array.from({ length: maxLaps }, (_, i) => i);

                  return (
                    <div key={category} className="mb-10">
                      <h2 className="capitalize">{category}</h2>

                      <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse text-sm">
                          <thead>
                            <tr>
                              <th className={thClass}>#</th>
                              <th className={thClass}>Bib</th>
                              <th className={thClass}>Name</th>
                              {hasGender && (
                                <>
                                  <th className={thClass}>Gender</th>
                                  <th className={thClass}>Gender #</th>
                                </>
                              )}
                              {hasCategory && (
                                <>
                                  <th className={thClass}>Category</th>
                                  <th className={thClass}>Cat #</th>
                                </>
                              )}
                              <th className={thClass}>Laps</th>
                              {lapColumns.map((i) => (
                                <th key={i} className={thClass}>
                                  Lap {i + 1}
                                </th>
                              ))}
                              <th className={thClass}>Total</th>
                            </tr>
                          </thead>
                          <tbody>
                            {entries.map((entry: LeaderboardEntry) => (
                              <tr
                                key={entry.bibNumber}
                                className={
                                  entry.position === 1 || entry.genderPosition === 1
                                    ? 'font-bold'
                                    : undefined
                                }
                              >
                                <td className={tdClass}>{entry.position}</td>
                                <td className={tdClass}>{entry.bibNumber}</td>
                                <td className={tdClass}>
                                  {entry.displayName}
                                  {entry.club && (
                                    <span className="text-gray-500 font-normal"> ({entry.club})</span>
                                  )}
                                </td>
                                {hasGender && (
                                  <>
                                    <td className={tdClass}>{entry.gender ?? '—'}</td>
                                    <td className={tdClass}>
                                      {entry.genderPosition != null
                                        ? formatOrdinal(entry.genderPosition)
                                        : '—'}
                                    </td>
                                  </>
                                )}
                                {hasCategory && (
                                  <>
                                    <td className={tdClass}>{entry.category ?? '—'}</td>
                                    <td className={tdClass}>
                                      {entry.categoryPosition != null
                                        ? formatOrdinal(entry.categoryPosition)
                                        : '—'}
                                    </td>
                                  </>
                                )}
                                <td className={tdClass}>{entry.lapsCompleted}</td>
                                {lapColumns.map((i) => (
                                  <td key={i} className={tdClass}>
                                    {entry.lapSplits[i] != null ? formatElapsed(entry.lapSplits[i]) : '—'}
                                  </td>
                                ))}
                                <td className={tdClass}>{formatElapsed(entry.currentTime)}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  );
                })
              )}
            </>
          )}
        </Container>
      </Stack>
    </>
  );
}
