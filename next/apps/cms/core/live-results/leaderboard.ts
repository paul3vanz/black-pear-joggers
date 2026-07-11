import {
  FinishRow,
  LeaderboardEntry,
  ParticipantRow,
  RaceRow,
} from './types';

// Team entries share one bib/team_name row instead of first/last name —
// mirrors participantDisplayName in race-timing/lib/db.ts.
function participantDisplayName(
  p: Pick<ParticipantRow, 'first_name' | 'last_name' | 'team_name'>
): string | undefined {
  return p.team_name ?? ([p.first_name, p.last_name].filter(Boolean).join(' ') || undefined);
}

const CATEGORY_ORDER = ['solo', 'pairs', 'teams'];

export function sortCategoryKeys(keys: string[]): string[] {
  return [...keys].sort((a, b) => {
    const ai = CATEGORY_ORDER.indexOf(a.toLowerCase());
    const bi = CATEGORY_ORDER.indexOf(b.toLowerCase());
    if (ai !== -1 || bi !== -1) {
      return (ai === -1 ? CATEGORY_ORDER.length : ai) - (bi === -1 ? CATEGORY_ORDER.length : bi);
    }
    return a.localeCompare(b);
  });
}

// Coarse ordering for races within an event — in practice one race spans
// the whole lapped event and every lap is a repeat finish row for the same
// bib within it (see buildLeaderboard), but this stays as a tiebreaker in
// case an event ever does span more than one race row.
export function sortRacesByLapOrder(races: RaceRow[]): RaceRow[] {
  return [...races].sort((a, b) => a.created_at.localeCompare(b.created_at));
}

// Ranks already-sorted entries within whatever group keyOf partitions them
// into (e.g. gender, age category) — entries arriving pre-sorted by the
// overall leaderboard order means a running per-key counter is enough to
// derive standings, no full re-sort per group.
function assignGroupPositions(
  entries: LeaderboardEntry[],
  keyOf: (entry: LeaderboardEntry) => string | null,
  assign: (entry: LeaderboardEntry, position: number) => void
): void {
  const counts = new Map<string, number>();
  for (const entry of entries) {
    const key = keyOf(entry);
    if (!key) continue;
    const next = (counts.get(key) ?? 0) + 1;
    counts.set(key, next);
    assign(entry, next);
  }
}

// Builds one ranked leaderboard per sub_category from raw lap-race data.
// Deliberately doesn't run race-timing's timer/bib reconciliation (lib/reconcile.ts) —
// per-lap "keep it simple" scope: finish times are the bib-key ("gun") time as
// recorded, not aligned against Timer taps.
//
// A lapped event is (in practice) one race, with each lap recorded as a
// separate direct-entry finish row sharing the same (race_id, bib_number) —
// the schema's per-bib uniqueness only applies once a finish is *linked* to
// a timer tap (see finishes_race_bib_idx), so repeat orphan rows for the
// same bib are exactly how multiple laps show up here. Every one of them is
// treated as a genuine lap, ordered by gun_time — there's no reliable way to
// tell a real repeat lap apart from an accidental duplicate entry from the
// raw data alone, and per the "keep it simple" scope that's left for the
// timing app's own Review/reconciliation flow (which sets `duplicate_of`,
// already filtered out via the query) rather than guessed at here.
export function buildLeaderboard(
  races: RaceRow[],
  participants: ParticipantRow[],
  finishes: FinishRow[]
): Record<string, LeaderboardEntry[]> {
  const raceOrder = new Map(sortRacesByLapOrder(races).map((r, index) => [r.id, index]));

  // Roster is re-imported per lap-race, so the same bib appears once per
  // race — any of them carries the same identity, just take the first.
  const participantByBib = new Map<string, ParticipantRow>();
  for (const p of participants) {
    if (!participantByBib.has(p.bib_number)) participantByBib.set(p.bib_number, p);
  }

  const finishesByBib = new Map<string, FinishRow[]>();
  for (const f of finishes) {
    if (f.gun_time == null) continue;
    const list = finishesByBib.get(f.bib_number) ?? [];
    list.push(f);
    finishesByBib.set(f.bib_number, list);
  }

  const grouped: Record<string, LeaderboardEntry[]> = {};
  for (const [bibNumber, bibFinishes] of finishesByBib) {
    // Ordered by race (in the rare case an event spans more than one), then
    // by gun_time within a race — which is lap order, since every lap is a
    // finish row against the same shared race start.
    const sorted = [...bibFinishes].sort(
      (a, b) =>
        (raceOrder.get(a.race_id) ?? 0) - (raceOrder.get(b.race_id) ?? 0) ||
        (a.gun_time as number) - (b.gun_time as number)
    );
    const latest = sorted[sorted.length - 1];
    const participant = participantByBib.get(bibNumber);

    // Each lap's split is the gap since this bib's previous lap (lap 1's
    // "previous" is the shared race start, i.e. 0).
    const lapSplits: number[] = sorted.map((finish, index) => {
      const previous = index > 0 ? (sorted[index - 1].gun_time as number) : 0;
      return (finish.gun_time as number) - previous;
    });

    const entry: LeaderboardEntry = {
      bibNumber,
      displayName: (participant && participantDisplayName(participant)) || `Bib ${bibNumber}`,
      club: participant?.club || null,
      gender: participant?.gender || null,
      category: participant?.category || null,
      lapsCompleted: sorted.length,
      lapSplits,
      currentTime: latest.gun_time as number,
      position: 0,
      genderPosition: null,
      categoryPosition: null,
    };

    const category = participant?.sub_category || 'Results';
    (grouped[category] ??= []).push(entry);
  }

  for (const entries of Object.values(grouped)) {
    entries.sort((a, b) => b.lapsCompleted - a.lapsCompleted || a.currentTime - b.currentTime);
    entries.forEach((entry, index) => {
      entry.position = index + 1;
    });
    assignGroupPositions(
      entries,
      (entry) => entry.gender,
      (entry, position) => {
        entry.genderPosition = position;
      }
    );
    assignGroupPositions(
      entries,
      (entry) => entry.category,
      (entry, position) => {
        entry.categoryPosition = position;
      }
    );
  }

  return grouped;
}

function pad2(n: number): string {
  return n.toString().padStart(2, '0');
}

// Mirrors formatGunTime in race-timing/app/race/[raceId]/bib.tsx and review.tsx
// so times read the same here as they do on the timing devices.
export function formatElapsed(ms: number): string {
  const totalSec = Math.floor(ms / 1000);
  const sec = totalSec % 60;
  const totalMin = Math.floor(totalSec / 60);
  const min = totalMin % 60;
  const hrs = Math.floor(totalMin / 60);
  return hrs > 0 ? `${pad2(hrs)}:${pad2(min)}:${pad2(sec)}` : `${pad2(min)}:${pad2(sec)}`;
}

export function formatOrdinal(n: number): string {
  const mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 13) return `${n}th`;
  switch (n % 10) {
    case 1:
      return `${n}st`;
    case 2:
      return `${n}nd`;
    case 3:
      return `${n}rd`;
    default:
      return `${n}th`;
  }
}
