import useSWR from 'swr';
import { config } from '../helpers/config';
import { MemberResponse, MembersResponse } from './members.interface';

const fetcher = (url) => fetch(url).then((res) => {
    const data = res.json();

    return data;
});

export function useMembers(clubId: number) {
    const { data, error } = useSWR<MembersResponse, string>(`${config.baseApiUrl}/membership/members/${clubId}`, fetcher);

    return {
        members: data,
        isLoading: !error && !data,
        isError: error
    }
};

export function useMember(urn: number) {
    const { data, error } = useSWR<MemberResponse, string>(`${config.baseApiUrl}/membership/${urn}`, fetcher);

    return {
        member: data,
        isLoading: !error && !data,
        isError: error
    }
};


