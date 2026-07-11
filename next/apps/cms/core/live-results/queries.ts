import { supabase } from './supabase-client';
import { buildLeaderboard } from './leaderboard';
import { EventRow, FinishRow, LiveResultsData, ParticipantRow, RaceRow } from './types';

// Priority when no ?event= override is given: show whatever's live right
// now, then fall back to the most recently finished event so results don't
// vanish the moment the race director marks it finished.
const STATUS_PRIORITY: Record<EventRow['status'], number> = {
  active: 0,
  finished: 1,
  pending: 2,
};

async function getEventById(eventId: string): Promise<EventRow | null> {
  const { data, error } = await supabase
    .from('events')
    .select('id, name, date, location, status')
    .eq('id', eventId)
    .maybeSingle();
  if (error) throw new Error(`getEventById: ${error.message}`);
  return data;
}

async function getMostRelevantEvent(): Promise<EventRow | null> {
  const { data, error } = await supabase
    .from('events')
    .select('id, name, date, location, status')
    .order('date', { ascending: false });
  if (error) throw new Error(`getMostRelevantEvent: ${error.message}`);
  if (!data || data.length === 0) return null;

  return [...data].sort((a, b) => STATUS_PRIORITY[a.status] - STATUS_PRIORITY[b.status])[0];
}

async function getRacesForEvent(eventId: string): Promise<RaceRow[]> {
  const { data, error } = await supabase
    .from('races')
    .select('id, name, created_at')
    .eq('event_id', eventId);
  if (error) throw new Error(`getRacesForEvent: ${error.message}`);
  return data ?? [];
}

async function getParticipantsForRaces(raceIds: string[]): Promise<ParticipantRow[]> {
  const { data, error } = await supabase
    .from('participants')
    .select('race_id, bib_number, first_name, last_name, team_name, gender, category, sub_category, club')
    .in('race_id', raceIds);
  if (error) throw new Error(`getParticipantsForRaces: ${error.message}`);
  return data ?? [];
}

async function getFinishesForRaces(raceIds: string[]): Promise<FinishRow[]> {
  const { data, error } = await supabase
    .from('finishes')
    .select('race_id, bib_number, gun_time')
    .in('race_id', raceIds)
    .is('duplicate_of', null)
    .not('gun_time', 'is', null);
  if (error) throw new Error(`getFinishesForRaces: ${error.message}`);
  return data ?? [];
}

export async function fetchLiveResults(eventId?: string): Promise<LiveResultsData> {
  const event = eventId ? await getEventById(eventId) : await getMostRelevantEvent();
  if (!event) return { event: null, races: [], leaderboardByCategory: {} };

  const races = await getRacesForEvent(event.id);
  if (races.length === 0) return { event, races, leaderboardByCategory: {} };

  const raceIds = races.map((r) => r.id);
  const [participants, finishes] = await Promise.all([
    getParticipantsForRaces(raceIds),
    getFinishesForRaces(raceIds),
  ]);

  return {
    event,
    races,
    leaderboardByCategory: buildLeaderboard(races, participants, finishes),
  };
}
