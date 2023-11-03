export interface MagicMile {
  id?: number;
  athleteId: number;
  firstName: string;
  lastName: string;
  gender: string;
  category: string;
  date: string;
  location: string;
  predictedTimeFormatted: string;
  predictedTime: number;
  actualTimeFormatted: string;
  actualTime: number;
  createdAt?: string;
  updatedAt?: string;
}
