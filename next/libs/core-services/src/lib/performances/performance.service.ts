import { format, subMonths } from 'date-fns';
import { PerformanceFilters } from './performance.type';

const apiBaseUrl = 'https://bpj.org.uk/api/public/index.php';

export function getPersonalBests(): Promise<Response> {
    return fetch(`${apiBaseUrl}/performances?limit=50&isPersonalBest=1&fromDate=${format(subMonths(new Date(), 1), 'yyyy-MM-dd')}`);
}



export function getPerformances(filters: Partial<PerformanceFilters>): Promise<Response> {
    const params = new URLSearchParams({
        athleteId: filters.athleteId ? filters.athleteId.toString() : '',
        search: filters.search || '',
        gender: filters.gender ? filters.gender.toString() : '',
        category: filters.category ? filters.category.toString() : '',
        isPersonalBest: filters.isPersonalBest ? '1' : '',
        distance: filters.distance ? filters.distance.toString() : '',
        limit: filters.limit ? filters.limit.toString() : '',
        page: filters.page ? filters.page.toString() : '',
        year: filters.year ? filters.year.toString() : '',
        includeAllMembers: '1',
    }).toString();

    return fetch(`${apiBaseUrl}/performances?${params}`);
}