import { AwardClaimRace } from './award-claim-race.model';

export interface AwardClaim {
  id?: number;
  athleteId?: number;
  gender: string;
  category: string;
  award: string;
  firstName: string;
  lastName: string;
  email: string;
  races: AwardClaimRace[];
}
