import useSWRImmutable from 'swr';
import { config } from '../config';
import { fetcher, fetcherConfig, post } from './fetcher';
import { User } from './user.interface';


export const userUrl = `${config.baseApiUrl}/user`;

export function useUser(shouldFetch = true) {
    const { data, error, isValidating } = useSWRImmutable<User, string>(shouldFetch ? userUrl : null, fetcher, fetcherConfig);

    return {
        user: data,
        isLoading: isValidating,
        isError: error
    }
};

export function setAthlete(athleteId: number): Promise<Response> {
    return post(`${config.baseApiUrl}/user`, { athleteId }, 'PUT');
}
