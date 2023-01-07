export type Performance = {
    award?: number;
    athleteId: number;
    firstName: string;
    lastName: string;
    gender: string;
    membershipStatus: string;
    id: number;
    category: string;
    event: string;
    time: string;
    timeParsed: string;
    meetingId: number;
    meetingName: string;
    date: string;
    isPersonalBest: number;
}

export enum AgeCategory {
    U20,
    U23,
    SEN,
    V35,
    V40,
    V45,
    V50,
    V55,
    V60,
    V65,
    V70,
    V75,
    V80,
};

export enum Gender {
    M,
    W,
}

export enum Event {
    'Mile',
    '5K',
    '10K',
    'Half Marathon',
    'Marathon'
}

export type PerformanceFilters = {
    athleteId: number;
    search: string;
    category: AgeCategory;
    gender: Gender;
    event: Event;
    fromDate: string;
    toDate: string;
    isPersonalBest: boolean;
    limit: number;
    meetingId: string;
    onlyAwards: boolean;
    sort: 'date' | 'athlete';
}