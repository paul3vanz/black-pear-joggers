import { Result } from './result';

export class Athlete {
    id: number;
    first_name: string;
    last_name: string;
    gender: string;
    category: string;
    latest_performance: Result;
    first_performance: Result;
}
