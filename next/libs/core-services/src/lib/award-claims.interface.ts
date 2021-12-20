export interface AwardClaimRace {
  id: number;
  claimId: number;
  distance: string;
  time: string;
  timeParsed: number;
  date: string;
  race: string;
  award: string;
  createdDate: string;
  updatedDate: string;
  checks: any;
}

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