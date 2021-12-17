import useSWRImmutable from 'swr/immutable';
import { Athlete } from './athletes.interface';
import { config } from '../helpers/config';
import { fetcher } from './fetcher';

export function useAthletes() {
    const { data, error } = useSWRImmutable<Athlete[], string>(`${config.baseApiUrl}/athletes`, fetcher);

    return {
        athletes: data,
        isLoading: !error && !data,
        isError: error
    }
};

export function useAthleteIdvCheck(urn: number, dateOfBirth: string) {
    console.log('service', urn, dateOfBirth);

    const { data, error } = useSWRImmutable<Athlete, string>((urn && dateOfBirth) ? `${config.baseApiUrl}/athleteIdvCheck?urn=${urn}&dob=${dateOfBirth}` : null, fetcher);

    console.log(data);

    return {
        athlete: data,
        isLoading: !error && !data,
        isError: error
    }
};

export function useAthlete(athleteId?: number) {
    const { data, error } = useSWRImmutable<Athlete, string>(athleteId ? `${config.baseApiUrl}/athlete/${athleteId}` : null, fetcher);

    return {
        athlete: data,
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
