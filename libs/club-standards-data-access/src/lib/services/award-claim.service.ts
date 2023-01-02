import * as moment from 'moment-mini-ts';
import { AwardClaim } from '../models/award-claim.model';
import { AwardClaimRace } from '../models/award-claim-race.model';
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';



@Injectable({
    providedIn: 'root'
})
export class AwardClaimService {
    constructor(private http: HttpClient) { }

    readonly API_URL = 'https://bpj.org.uk/api/public/index.php';

    getAll(): Observable<AwardClaim[]> {
        return this.http.get<AwardClaim[]>(`${this.API_URL}/awardclaim`).pipe(
            map((awardClaims: AwardClaim[]) => {
                return awardClaims.map((awardClaim: AwardClaim) => {
                    return {
                        ...awardClaim,
                        checks: {
                            racesAreInSameYear: null
                        }
                    };
                });
            })
        );
    }

    getCertificate(id: number, token: string): Observable<AwardClaim> {
        return this.http.get<AwardClaim>(
            `${this.API_URL}/awardclaim/${id}/${token}`
        );
    }

    toggleVerified(awardClaim: AwardClaim): Observable<AwardClaim> {
        return this.http.post<AwardClaim>(
            `${this.API_URL}/awardclaim/toggleverified/${awardClaim.id}`,
            null
        );
    }

    archive(awardClaim: AwardClaim): Observable<AwardClaim> {
        return this.http.post<AwardClaim>(
            `${this.API_URL}/awardclaim/archive/${awardClaim.id}`,
            null
        );
    }

    delete(awardClaim: AwardClaim): Observable<AwardClaim> {
        return this.http.post<AwardClaim>(
            `${this.API_URL}/awardclaim/delete/${awardClaim.id}`,
            null
        );
    }

    updateRace(awardClaimRace: AwardClaimRace) {
        return this.http.post<AwardClaimRace>(
            `${this.API_URL}/awardclaim/${awardClaimRace.claimId}/race`,
            awardClaimRace
        );
    }

    update(awardClaim: AwardClaim) {
        return this.http.post(`${this.API_URL}/awardclaim`, awardClaim);
    }

    // MANUAL CHECKS
    // Matched up person with known member? - Need membership list/api
    // Is the person a paid up member? - Need membership list/api
    // Is their age category correct? - Need DOB
    // Were all events were completed in the same age category? - Need DOB
    // Have all finish times have been verified?

    // Do all events meet the minimum time for the award being claimed?
    checkRacesMeetStandardClaimed(awardClaim: AwardClaim) {
        return true;
    }

    // Are all events are in same calendar year?
    checkRacesAreInSameYear(awardClaim: AwardClaim) {
        console.log('checkRacesAreInSameYear');
        return awardClaim.races.every(
            race => moment(race.date).year === moment(awardClaim.races[0].date).year
        );
    }
}
