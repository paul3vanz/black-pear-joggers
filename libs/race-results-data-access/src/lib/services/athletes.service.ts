import { Athlete } from '../models/athlete.model';
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class AthletesService {
    athletesUrl = 'https://bpj.org.uk/api/public/index.php/athletes';
    athleteUrl = 'https://bpj.org.uk/api/public/index.php/athlete';

    constructor(private http: HttpClient) { }

    getAthletes(searchTerm?: string): Observable<Athlete[]> {
        return this.http.get<Athlete[]>(
            `${this.athletesUrl}?search=${searchTerm}&active=1`
        );
    }

    getAthlete(athleteId: number): Observable<Athlete> {
        return this.http.get<Athlete>(`${this.athleteUrl}/${athleteId}`);
    }

    selectAthlete(athleteId: number) {
        return localStorage.setItem('bpj.athlete.selected', athleteId.toString());
    }
}
