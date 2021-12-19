import useSWRImmutable from 'swr';
import { config } from '../helpers/config';
import { fetcher, post } from './fetcher';
import { MagicMileResult } from './magic-mile.interface';
import { User } from './user.interface';


export const userUrl = `${config.baseApiUrl}/user`;

export function useUser() {
    const { data, error } = useSWRImmutable<User, string>(userUrl, fetcher);

    return {
        user: data,
        isLoading: !error && !data,
        isError: error
    }
};

export function setAthlete(athleteId: number): Promise<Response> {
    return post(`${config.baseApiUrl}/user`, {athleteId}, 'PUT');
}
