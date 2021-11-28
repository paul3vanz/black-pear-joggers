import useSWR from 'swr';
import { config } from '../helpers/config';
import { Athlete } from './athletes.interface';

const fetcher = (url) => fetch(url).then((res) => {
    const data = res.json();

    return data;
});

export function useAthletes() {
    const { data, error } = useSWR<Athlete[], string>(`${config.baseApiUrl}/athletes`, fetcher);

    return {
        athletes: data,
        isLoading: !error && !data,
        isError: error
    }
};


