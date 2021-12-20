import useSWRImmutable from 'swr';
import { config } from '../config';
import { fetcher, post } from './fetcher';
import { User } from './user.interface';


export const userUrl = `${config.baseApiUrl}/user`;

export function useUser() {
    const { data, error, isValidating } = useSWRImmutable<User, string>(userUrl, fetcher);

    return {
        user: data,
        isLoading: isValidating,
        isError: error
    }
};

export function setAthlete(athleteId: number): Promise<Response> {
    return post(`${config.baseApiUrl}/user`, {athleteId}, 'PUT');
}
