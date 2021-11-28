import useSWR from 'swr';
import { config } from '../helpers/config';
import { ClubsResponse } from './clubs.interface';

const fetcher = (url) => fetch(url).then((res) => {
    const data = res.json();

    return data;
});

export function useClubs() {
    const { data, error } = useSWR<ClubsResponse, string>(`${config.baseApiUrl}/membership/clubs`, fetcher);

    return {
        clubs: data,
        isLoading: !error && !data,
        isError: error
    }
};


