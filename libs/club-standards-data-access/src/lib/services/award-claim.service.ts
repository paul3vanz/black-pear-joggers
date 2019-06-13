import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AwardClaim } from '../models/award-claim.model';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class AwardClaimService {
  constructor(private http: HttpClient) {}

  getAll(): Observable<AwardClaim[]> {
    return this.http.get<AwardClaim[]>('https://bpj.org.uk/api/public/index.php/awardclaim');
  }

  getCertificate(id: number, token: string): Observable<AwardClaim> {
    return this.http.get<AwardClaim>(`https://bpj.org.uk/api/public/index.php/awardclaim/${id}/${token}`);
  }

  validateClaim(id: number): boolean {
    return true;
  }
}
