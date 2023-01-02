import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Ranking } from '../models/ranking.model';

@Injectable()
export class RankingsService {
    constructor(private http: HttpClient) { }

    loadRankings(athleteId: number): Observable<Ranking[]> {
        return this.http.get<Ranking[]>(
            `https://bpj.org.uk/api/public/index.php/rankings/${athleteId}`
        );
    }

    fetchRankings(athleteId: number): Observable<any[]> {
        return this.http.get<any[]>(
            `https://bpj.org.uk/api/public/index.php/fetch/rankings/${athleteId}`
        );
    }
}
