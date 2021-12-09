import useSWRImmutable from 'swr/immutable';
import { config } from '../helpers/config';
import { fetcher, post } from './fetcher';
import { AwardClaim, AwardClaimRace, Standard } from './award-claims.interface';

export const awardClaimsUrl = `${config.baseApiUrl}/awardclaim`;

export function useAwardClaims() {
    const { data, error } = useSWRImmutable<AwardClaim[], string>(awardClaimsUrl, fetcher);

    return {
        awardClaims: data,
        isLoading: !error && !data,
        isError: error
    }
};

export async function toggleVerified(awardClaim: AwardClaim): Promise<AwardClaim> {
    const response = await post(`${config.baseApiUrl}/awardclaim/toggleverified/${awardClaim.id}`);

    return response.ok ? response.json() : null;
}

export async function archive(awardClaim: AwardClaim): Promise<boolean> {
    const response = await post(`${config.baseApiUrl}/awardclaim/archive/${awardClaim.id}`);

    return response.ok ? true : false;
}

export async function remove(awardClaim: AwardClaim): Promise<boolean> {
    const response = await post(`${config.baseApiUrl}/awardclaim/delete/${awardClaim.id}`);

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
//   // Were all events were completed in the same age category? - Need DOB
//   // Have all finish times have been verified?

//   // Do all events meet the minimum time for the award being claimed?
//   checkRacesMeetStandardClaimed(awardClaim: AwardClaim) {
//     return true;
//   }

//   // Are all events are in same calendar year?
//   checkRacesAreInSameYear(awardClaim: AwardClaim) {
//     console.log('checkRacesAreInSameYear');
//     return awardClaim.races.every(
//       race => moment(race.date).year === moment(awardClaim.races[0].date).year
//     );
//   }

// export function createMagicMileResult(magicMileResult: MagicMileResult) {
//     fetch(`${config.baseApiUrl}/magicmile`, {
//         method: 'POST',
//         headers: {
//             'Content-Type': 'application/json',
//           },
//         body: JSON.stringify(magicMileResult),
//     })
// }
