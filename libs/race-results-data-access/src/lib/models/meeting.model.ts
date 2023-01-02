import { Athlete } from './athlete.model';

export interface Meeting {
    id: string;
    ukaMeetingId: string;
    date: string;
    name: string;
    event: string;
    athlete: Athlete;
    createdDate: string;
    updatedDate: string;
    performancesCount: number;
}
