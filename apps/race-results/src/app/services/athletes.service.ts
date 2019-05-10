import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Athlete } from '../models/athlete';
import { Paging } from '../models/paging';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class AthletesService {
  athletesUrl = '//bpj.org.uk/api/public/index.php/athletes';
  athleteUrl = '//bpj.org.uk/api/public/index.php/athlete/';

  constructor(private http: HttpClient) {}

  getAthletes(searchTerm?: string): Observable<Paging<Athlete>> {
    return this.http.get<Paging<Athlete>>(`${this.athletesUrl}?search=${searchTerm}&active=1`);
  }

  getAthlete(athleteId: string): Observable<Athlete> {
    return this.http.get<Athlete>(this.athleteUrl + athleteId);
  }

  selectAthlete(athleteId: number) {
    return localStorage.setItem('bpj.athlete.selected', athleteId.toString());
  }
}
