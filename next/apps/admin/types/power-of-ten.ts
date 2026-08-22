export interface FetchPerformancesResult {
  success: boolean;
  athleteId: number;
  added: number;
  firstDate: string | null;
  lastDate: string | null;
  message: string | null;
}

export interface FetchRankingsResult {
  success: boolean;
  athleteId: number;
  added: number;
  message: string | null;
}

export interface FetchAthleteResult {
  success: boolean;
  athleteId: number;
  name: string | null;
  message: string | null;
  performances: FetchPerformancesResult;
  rankings: FetchRankingsResult;
}

export interface QueueResult {
  queued: number;
  athleteIds: number[];
}
