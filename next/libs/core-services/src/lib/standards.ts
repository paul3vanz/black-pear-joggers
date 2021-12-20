import useSWRImmutable from 'swr';
import { config } from '../config';
import { fetcher } from './fetcher';
import { Standard } from './standards.interface';

export function useStandards() {
  const { data, error } = useSWRImmutable<Standard[], string>(
    `${config.baseApiUrl}/standards`,
    fetcher
  );

  return {
    standards: data,
    isLoading: !error && !data,
    isError: error,
  };
}
