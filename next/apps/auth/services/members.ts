import useSWRImmutable from 'swr';
import { config } from '../helpers/config';
import { MemberResponse, MembersResponse } from './members.interface';
import { fetcher } from './fetcher';

export function useMembers(clubId: number) {
    const { data, error } = useSWRImmutable<MembersResponse, string>(`${config.baseApiUrl}/clubs/${clubId}/members`, fetcher);

    return {
        members: data,
        isLoading: !error && !data,
        isError: error
    }
};

export function useMember(urn: number) {
    const { data, error } = useSWRImmutable<MemberResponse, string>(`${config.baseApiUrl}/membership/${urn}`, fetcher);

    return {
        member: data && {
            ...data,
            ForeignFlag: JSON.parse(data.ForeignFlag.toLowerCase())
        },
        isLoading: !error && !data,
        isError: error
    }
};


