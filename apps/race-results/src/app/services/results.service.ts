import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Meeting } from '../models/meeting';
import { Observable } from 'rxjs';
import { Paging } from '../models/paging';
import { Result } from '@black-pear-joggers/race-results-data-access';


@Injectable()
export class ResultsService {
    apiRoot = 'https://bpj.org.uk/api/public/index.php';
    performancesUrl = '/performances';
    meetingsUrl = '/meetings';

    constructor(private http: HttpClient) { }

    getMeetingResults(date: string, meetingId: string): Observable<Paging<Result>> {
        return this.http.get<Paging<Result>>(`${this.apiRoot}${this.performancesUrl}/${date}/${meetingId}`);
    }

    getAthleteResults(athleteId: number, page?: number): Observable<Paging<Result>> {
        return this.http.get<Paging<Result>>(`${this.apiRoot}${this.performancesUrl}?athleteId=${athleteId}&limit=1000&page=${page}`);
    }

    getEvents(search: string): Observable<Paging<Meeting>> {
        return this.http.get<Paging<Meeting>>(`${this.apiRoot}${this.meetingsUrl}?search=${search}`);
    }
}
