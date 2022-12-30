export interface Meeting {
    id: string;
    ukaMeetingId: number | null;
    event: string;
    name: string;
    date: string;
    performancesCount: number;
    athlete: {
        first_name: string;
        last_name: string;
    }
    createdDate: string;
    updatedDate: string;
}
