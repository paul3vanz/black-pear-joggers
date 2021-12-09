import useSWRImmutable from 'swr';
import { config } from '../helpers/config';
import { fetcher } from './fetcher';
import { AwardClaim, AwardClaimRace, Standard } from './award-claims.interface';

export function useAwardClaims() {
    const { data, error } = useSWRImmutable<AwardClaim[], string>(`${config.baseApiUrl}/awardclaim`, fetcher);

    return {
        awardClaims: data,
        isLoading: !error && !data,
        isError: error
    }
};

// getCertificate(id: number, token: string): Observable<AwardClaim> {
//     return this.http.get<AwardClaim>(
//       `${this.API_URL}/awardclaim/${id}/${token}`
//     );
//   }

//   toggleVerified(awardClaim: AwardClaim): Observable<AwardClaim> {
//     return this.http.post<AwardClaim>(
//       `${this.API_URL}/awardclaim/toggleverified/${awardClaim.id}`,
//       null
//     );
//   }

//   archive(awardClaim: AwardClaim): Observable<AwardClaim> {
//     return this.http.post<AwardClaim>(
//       `${this.API_URL}/awardclaim/archive/${awardClaim.id}`,
//       null
//     );
//   }

//   delete(awardClaim: AwardClaim): Observable<AwardClaim> {
//     return this.http.post<AwardClaim>(
//       `${this.API_URL}/awardclaim/delete/${awardClaim.id}`,
//       null
//     );
//   }

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
