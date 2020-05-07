import { Ranking } from './ranking.model';

export interface YearRankingStats {
  year: number;
  highest: Ranking;
  lowest: Ranking;
  first: Ranking;
  last: Ranking;
  improvement: {
    number: number;
    percentage: number;
  };
}
