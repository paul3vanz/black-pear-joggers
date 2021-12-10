import useSWRImmutable from 'swr';
import { config } from '../helpers/config';
import { Standard } from './standards.interface';
import { fetcher } from './fetcher';

export function useStandards() {
  const { data, error } = useSWRImmutable<Standard[], string>(
    `${config.baseApiUrl}standards`,
    fetcher
  );

  return {
    standards: data,
    isLoading: !error && !data,
    isError: error,
  };
}
