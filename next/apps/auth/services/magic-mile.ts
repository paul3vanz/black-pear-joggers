import useSWRImmutable from 'swr';
import { config } from '../helpers/config';
import { MagicMileResult } from './magic-mile.interface';
import { fetcher } from './fetcher';

export function useMagicMileResults() {
    const { data, error } = useSWRImmutable<MagicMileResult[], string>(`${config.baseApiUrl}/magicmile`, fetcher);

    return {
        magicMileResults: data,
        isLoading: !error && !data,
        isError: error
    }
};

export function createMagicMileResult(magicMileResult: MagicMileResult) {
    fetch(`${config.baseApiUrl}/magicmile`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
          },
        body: JSON.stringify(magicMileResult),
    })
}
