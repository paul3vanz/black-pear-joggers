import { AwardClaimRace } from './award-claim-race.model';

export interface AwardClaim {
  id: number;
  athleteId?: any;
  gender: string;
  category: string;
  award: string;
  firstName: string;
  lastName: string;
  email: string;
  verified?: any;
  createdDate: string;
  updatedDate: string;
  races: AwardClaimRace[];
  archived: boolean;
  checks: any;
}
