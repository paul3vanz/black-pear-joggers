import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AwardClaim } from '../models/award-claim.model';
import { Observable } from 'rxjs';
import { ClubStandardsService } from 'apps/club-standards/src/app/services/club-standards.service';

import * as moment from 'moment-mini-ts';
import { map } from 'rxjs/operators';

@Injectable({
  providedIn: 'root',
})
export class AwardClaimService {
  constructor(
    private http: HttpClient,
    // private clubStandardsService: ClubStandardsService
  ) {}

  getAll(): Observable<AwardClaim[]> {
    return this.http.get<AwardClaim[]>('https://bpj.org.uk/api/public/index.php/awardclaim').pipe(
      map((awardClaims: AwardClaim[]) => {
        return awardClaims.map((awardClaim: AwardClaim) => {
          return {
            ...awardClaim,
            checks: {
              racesAreInSameYear: null,
            },
          };
        });
      })
    );
  }

  getCertificate(id: number, token: string): Observable<AwardClaim> {
    return this.http.get<AwardClaim>(`https://bpj.org.uk/api/public/index.php/awardclaim/${id}/${token}`);
  }

  toggleVerified(awardClaim: AwardClaim): Observable<AwardClaim> {
    return this.http.get<AwardClaim>(`https://bpj.org.uk/api/public/index.php/awardclaim/toggleverified/${awardClaim.id}`);
  }

  archive(awardClaim: AwardClaim): Observable<AwardClaim> {
    return this.http.get<AwardClaim>(`https://bpj.org.uk/api/public/index.php/awardclaim/archive/${awardClaim.id}`);
  }

  delete(awardClaim: AwardClaim): Observable<AwardClaim> {
    return this.http.get<AwardClaim>(`https://bpj.org.uk/api/public/index.php/awardclaim/delete/${awardClaim.id}`);
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
    return awardClaim.races.every((race) => moment(race.date).year === moment(awardClaim.races[0].date).year);
  }

}
