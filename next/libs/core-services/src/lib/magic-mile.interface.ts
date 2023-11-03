export interface MagicMileResult {
    id?: number;
    athleteId: number;
    firstName: string;
    lastName: string;
    gender: string;
    category: string;
    date: string;
    location: string;
    predictedTime: number;
    actualTime: number;
    predictedTimeFormatted?: string;
    actualTimeFormatted?: string;
    createdDate?: string;
    updatedDate?: string;
  }
