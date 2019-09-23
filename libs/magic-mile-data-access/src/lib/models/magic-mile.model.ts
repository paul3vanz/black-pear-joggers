export interface MagicMile {
  id?: number;
  athleteId: number;
  firstName: string;
  lastName: string;
  gender: string;
  category: string;
  date: string;
  location: string;
  predictedTime: string;
  predictedTimeParsed: number;
  actualTime: string;
  actualTimeParsed: number;
  createdAt?: string;
  updatedAt?: string;
}
