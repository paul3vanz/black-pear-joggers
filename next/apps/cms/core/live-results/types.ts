// Mirrors the subset of race-timing's Supabase schema this viewer reads —
// see race-timing/supabase/migrations/20260705120000_init_schema.sql onward.

export interface EventRow {
  id: string;
  name: string;
  date: string;
  location: string | null;
  status: 'pending' | 'active' | 'finished';
}

// One row per race under the event. In practice a lapped event is one race
// row, with each lap recorded as a repeat finish for the same bib within it
// — see buildLeaderboard in leaderboard.ts for how laps are actually derived.
export interface RaceRow {
  id: string;
  name: string;
  created_at: string;
}

export interface ParticipantRow {
  race_id: string;
  bib_number: string;
  first_name: string | null;
  last_name: string | null;
  team_name: string | null;
  gender: string | null;
  category: string | null; // age category, e.g. V40
  sub_category: string | null; // e.g. solo/pairs/teams — the leaderboard grouping
  club: string | null;
}

export interface FinishRow {
  race_id: string;
  bib_number: string;
  gun_time: number | null; // ms since that lap-race's start_time
}

export interface LeaderboardEntry {
  bibNumber: string;
  displayName: string;
  club: string | null;
  gender: string | null;
  category: string | null; // age category, e.g. V40
  lapsCompleted: number;
  // One entry per completed lap, in lap order (length === lapsCompleted).
  // Each value is the split — time since the previous lap, or since the
  // race start for lap 1.
  lapSplits: number[];
  currentTime: number; // ms — cumulative gun_time of the most recently completed lap
  position: number; // rank within this sub_category leaderboard
  genderPosition: number | null; // rank among entries sharing the same gender, within this sub_category
  categoryPosition: number | null; // rank among entries sharing the same age category, within this sub_category
}

export interface LiveResultsData {
  event: EventRow | null;
  races: RaceRow[];
  leaderboardByCategory: Record<string, LeaderboardEntry[]>;
}
