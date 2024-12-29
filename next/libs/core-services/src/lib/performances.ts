import { config } from '../config';
import { fetcher } from './fetcher';
import { useQuery } from '@tanstack/react-query';
import { Performance } from './performances/performance.type';
import { Paginate } from './common/types/paginate.type';

export function usePerformances(athleteId: number) {
  return useQuery<Paginate<Performance>>(['performances'], () =>
    fetcher(
      `${config.baseApiUrl}/performances?athleteId=${athleteId}&limit=1000`
    )
  );
}
