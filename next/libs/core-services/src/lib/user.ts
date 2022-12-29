import { config } from '../config';
import { fetcher, post } from './fetcher';
import { useQuery } from '@tanstack/react-query';
import { User } from './user.interface';

export const userUrl = `${config.baseApiUrl}/user`;

export function useUser(shouldFetch = true) {
    return useQuery<User>(['user'], () => fetcher(userUrl), {
        enabled: shouldFetch,
    });
};

export function setUserAthlete(athleteId: number): Promise<Response> {
    return post(`${config.baseApiUrl}/user`, { athleteId }, 'PUT');
}
