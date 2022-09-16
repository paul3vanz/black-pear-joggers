export interface PerformanceSummary {
    meeting_id: number;
    date: string;
    race: string;
    event: string;
    manual?: any;
    first_name: string;
    last_name: string;
    created_at: Date;
    updated_at: Date;
    total_results: number;
}