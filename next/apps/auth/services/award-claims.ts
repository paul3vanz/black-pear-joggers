import useSWRImmutable from 'swr/immutable';
import { config } from '../helpers/config';
import { fetcher, post } from './fetcher';
import { AwardClaim, Standard } from './award-claims.interface';
import { getYear, isSameYear, parseISO } from 'date-fns';

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

export async function remove(awardClaim: AwardClaim): Promise<boolean> {
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

//   update(awardClaim: AwardClaim) {
//     return this.http.post(`${this.API_URL}/awardclaim`, awardClaim);
//   }

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
  return false;
}

export function checkRacesCompletedInCorrectCategory(
  awardClaim: AwardClaim,
  standards: Standard[]
) {
  return false;
}
