import { Result } from './result';
import { Ranking } from '../../../../../libs/race-results-data-access/src/lib/models/ranking.model';

export interface Athlete {
  id: number;
  athlete_id: number;
  athlete_id_alt: number;
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
