import useSWRImmutable from 'swr/immutable';
import { Payment } from './athletes.interface';
import { config } from '../config';
import { fetcher, fetcherConfig } from './fetcher';


export function usePayments() {
    const { data, error, isValidating } = useSWRImmutable<Payment[], string>(`${config.baseApiUrl}/payments`, fetcher, fetcherConfig);

    return {
        payments: data,
        isLoading: isValidating,
        isError: error
    }
};
