import useSWRImmutable from 'swr';
import { config } from '../helpers/config';
import { Athlete } from './athletes.interface';
import { fetcher } from './fetcher';

export function useAthletes() {
    const { data, error } = useSWRImmutable<Athlete[], string>(`${config.baseApiUrl}/athletes`, fetcher);

    return {
        athletes: data,
        isLoading: !error && !data,
        isError: error
    }
};

export function updateAthlete(id: number, athlete: any) {
    fetch(`${config.baseApiUrl}/athletes/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
          },
        body: JSON.stringify(athlete),
    })
}
