import useSWRImmutable from 'swr';
import { config } from '../config';
import { fetcher, remove } from './fetcher';
import { MagicMileResult } from './magic-mile.interface';


export const magicMileResultsUrl = `${config.baseApiUrl}/magicmile`;

export function useMagicMileResults() {
    const { data, error } = useSWRImmutable<MagicMileResult[], string>(magicMileResultsUrl, fetcher);

    return {
        magicMileResults: data,
        isLoading: !error && !data,
        isError: error
    }
};

export function createMagicMileResult(magicMileResult: MagicMileResult): Promise<Response> {
    return fetch(`${config.baseApiUrl}/magicmile`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
          },
        body: JSON.stringify(magicMileResult),
    })
}

export async function destroy(awardClaim: MagicMileResult): Promise<boolean> {
    const response = await remove(
      `${config.baseApiUrl}/magicmile/${awardClaim.id}`
    );

    return response.ok ? true : false;
  }
