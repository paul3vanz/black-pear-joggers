import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { map } from 'rxjs/operators';
import { Membership } from '../models/membership.model';
import { Observable } from 'rxjs';

@Injectable({
    providedIn: 'root',
})
export class MembershipService {
    constructor(private http: HttpClient) { }

    fetchMembers(clubId: number): Observable<Membership[]> {
        return this.http
            .get<{ Athletes: Membership[] }>(`https://bpj.org.uk/api/public/index.php/membership/members/${clubId}`)
            .pipe(map((response) => response.Athletes));
    }
}
