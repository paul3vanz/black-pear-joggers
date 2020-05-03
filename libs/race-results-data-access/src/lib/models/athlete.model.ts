import { Result } from './result.model';
import { Ranking } from './ranking.model';

export interface Athlete {
  id: number;
  athlete_id: number;
  first_name: string;
  last_name: string;
  gender: string;
  category: string;
  created_at: string;
  updated_at: string;
  latest_performance: Result;
  first_performance: Result;
  latest_ranking: Ranking;
}
