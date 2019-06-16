import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AwardClaim } from '../models/award-claim.model';
import { Observable } from 'rxjs';
import { ClubStandardsService } from 'apps/club-standards/src/app/services/club-standards.service';

import * as moment from 'moment-mini-ts';

@Injectable({
  providedIn: 'root',
})
export class AwardClaimService {
  constructor(
    private http: HttpClient,
    // private clubStandardsService: ClubStandardsService
  ) {}

  getAll(): Observable<AwardClaim[]> {
    return this.http.get<AwardClaim[]>('https://bpj.org.uk/api/public/index.php/awardclaim');
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

// Matched up person with known member?
// Is the person a paid up member?
// Is their age category correct?
// Are all events are in same calendar year?
   checkRacesAreInSameYear(awardClaim: AwardClaim) {
     return awardClaim.races.every((race) => moment(race.date).year === moment(awardClaim.races[0].date).year);
   }
// Were all events were completed in the same age category?
// Do all events meet the minimum time for the award being claimed?
// Have all finish times have been verified?
}
