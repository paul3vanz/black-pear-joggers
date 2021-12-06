import useSWRImmutable from 'swr';
import { config } from '../helpers/config';
import { ClubsResponse } from './clubs.interface';
import { fetcher } from './fetcher';

export function useClubs() {
    const { data, error } = useSWRImmutable<ClubsResponse, string>(`${config.baseApiUrl}/clubs`, fetcher);

    return {
        clubs: data,
        isLoading: !error && !data,
        isError: error
    }
};


