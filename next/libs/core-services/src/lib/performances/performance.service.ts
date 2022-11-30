import { format, subMonths } from 'date-fns';

export function getPersonalBests(): Promise<Response> {
    return fetch(`https://bpj.org.uk/api/public/index.php/performancesindividual?isPersonalBest=1&fromDate=${format(subMonths(new Date(), 1), 'yyyy-MM-dd')}`);
}