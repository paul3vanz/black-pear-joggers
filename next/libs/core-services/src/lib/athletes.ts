import useSWRImmutable from 'swr/immutable';
import { Athlete } from './athletes.interface';
import { config } from '../config';
import { fetcher, fetcherConfig } from './fetcher';


export function useAthletes() {
    const { data, error, isValidating } = useSWRImmutable<Athlete[], string>(`${config.baseApiUrl}/athletes`, fetcher, fetcherConfig);

    return {
        athletes: data,
        isLoading: isValidating,
        isError: error
    }
};

export function useAthleteIdvCheck(urn: number, dateOfBirth: string) {
    const { data, error, isValidating } = useSWRImmutable<Athlete, string>((urn && dateOfBirth) ? `${config.baseApiUrl}/athleteIdvCheck?urn=${urn}&dob=${dateOfBirth}` : null, fetcher, fetcherConfig);

    return {
        athlete: data,
        isLoading: isValidating,
        isError: error
    }
};

export function useAthlete(athleteId?: number) {
    const { data, error } = useSWRImmutable<Athlete, string>(athleteId ? `${config.baseApiUrl}/athlete/${athleteId}` : null, fetcher, fetcherConfig);

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
