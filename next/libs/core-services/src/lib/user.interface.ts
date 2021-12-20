import { Athlete } from './athletes.interface';

export interface User {
    id: string;
    athleteId: number;
    createdDate: string;
    updatedDate: string;
    athlete: Athlete;
}