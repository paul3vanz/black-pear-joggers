import useSWRImmutable from 'swr/immutable';
import { AwardClaim, AwardClaimRace } from './award-claims.interface';
import { config } from '../config';
import { fetcher, post } from './fetcher';
import { getYear, isSameYear, parseISO } from 'date-fns';
import { Standard } from './standards.interface';


export const awardClaimsUrl = `${config.baseApiUrl}/awardclaim`;

export function useAwardClaims() {
  const { data, error } = useSWRImmutable<AwardClaim[], string>(
    awardClaimsUrl,
    fetcher
  );

  return {
    awardClaims: data,
    isLoading: !error && !data,
    isError: error,
  };
}

export function useMyAwardClaims(athleteId?: number) {
  const { data, error } = useSWRImmutable<AwardClaim[], string>(
    athleteId ? `${awardClaimsUrl}?athleteId=${athleteId}` : null,
    fetcher
  );

  return {
    myAwardClaims: data,
    isLoading: !error && !data,
    isError: error,
  };
}

export function useAwardClaim(id?: number, token?: string) {
  const { data, error } = useSWRImmutable<AwardClaim, string>(
    id && token ? `${config.baseApiUrl}/awardclaim/${id}/${token}` : null,
    fetcher
  );

  return {
    awardClaim: data,
    isLoading: !error && !data,
    isError: error,
  };
}

export type NewAwardClaim = Pick<
  AwardClaim,
  'gender' | 'category' | 'award' | 'firstName' | 'lastName' | 'email'
> & {
  races: Pick<AwardClaimRace, 'distance' | 'time' | 'timeParsed' | 'date' | 'race' | 'award'>[];
};

export async function submitClaim(claim: NewAwardClaim): Promise<AwardClaim> {
  const response = await post(awardClaimsUrl, claim);

  if (!response.ok) {
    throw new Error(response.status.toString());
  }

  return response.json();
}

export async function toggleVerified(
  awardClaim: AwardClaim
): Promise<AwardClaim> {
  const response = await post(
    `${config.baseApiUrl}/awardclaim/toggleverified/${awardClaim.id}`
  );

  return response.ok ? response.json() : null;
}

export async function archive(awardClaim: AwardClaim): Promise<boolean> {
  const response = await post(
    `${config.baseApiUrl}/awardclaim/archive/${awardClaim.id}`
  );

  return response.ok ? true : false;
}

export async function deleteClaim(awardClaim: AwardClaim): Promise<boolean> {
  const response = await post(
    `${config.baseApiUrl}/awardclaim/delete/${awardClaim.id}`
  );

  return response.ok ? true : false;
}

//   updateRace(awardClaimRace: AwardClaimRace) {
//     return this.http.post<AwardClaimRace>(
//       `${this.API_URL}/awardclaim/${awardClaimRace.claimId}/race`,
//       awardClaimRace
//     );
//   }

  export function update(id: number, updatedFields: Partial<AwardClaim>) {
    return post(`${config.baseApiUrl}/awardclaim/${id}`, updatedFields, 'PATCH');
  }

//   // MANUAL CHECKS
//   // Matched up person with known member? - Need membership list/api
//   // Is the person a paid up member? - Need membership list/api
//   // Is their age category correct? - Need DOB
//   // Have all finish times have been verified?

export function checkThreeOrMoreDistances(awardClaim: AwardClaim): boolean {
  const uniqueDistanceCount = new Set(
    awardClaim.races.map((race) => race.distance)
  ).size;

  return uniqueDistanceCount >= 3;
}

export function allEventsAreAllowedDistances(awardClaim: AwardClaim): boolean {
  return awardClaim.races.every((race) =>
    ['Mile', '5K', '10K', 'Half Marathon', 'Marathon'].includes(race.distance)
  );
}

export function checkRacesCompletedInSameCalendarYear(awardClaim: AwardClaim) {
  return (
    new Set(awardClaim.races.map((race) => getYear(parseISO(race.date))))
      .size === 1
  );
}

export function checkRacesMeetStandardClaimed(
  awardClaim: AwardClaim,
  standards: Standard[]
) {
    return awardClaim.races.every((race) => {
      const standardForEvent = standards.find((standard) => {
        return standard.category === awardClaim.category && standard.gender === awardClaim.gender && standard.event === race.distance;
      });

      const targetTime = standardForEvent?.time_parsed;

      return targetTime ? (race.timeParsed <= Number(targetTime)) : false;
    });
}

export function checkRacesCompletedInCorrectCategory(
  awardClaim: AwardClaim,
  standards: Standard[]
) {
  return false;
}
