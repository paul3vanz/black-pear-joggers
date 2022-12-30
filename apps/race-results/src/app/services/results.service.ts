import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Meeting } from '../models/meeting';
import { Observable } from 'rxjs';
import { Paging } from '../models/paging';
import { Result } from '../models/result';


@Injectable()
export class ResultsService {
    apiRoot = '//bpj.org.uk/api/public/index.php';
    resultsUrl = '//bpj.org.uk/api/public/index.php/performances?onlyAwards=0&fromDate=2017-01-01';
    athleteResultsUrlRoot = '//bpj.org.uk/api/public/index.php/performances?onlyAwards=0';
    performancesUrl = '//bpj.org.uk/api/public/index.php/performances';
    meetingsUrl = '//bpj.org.uk/api/public/index.php/meetings';

    constructor(private http: HttpClient) { }

    getResults(): Observable<Result[]> {
        return this.http.get<Result[]>(this.resultsUrl);
    }

    getMeetingResults(date: string, meetingId: string): Observable<Paging<Result>> {
        return this.http.get<Paging<Result>>(`${this.performancesUrl}/${date}/${meetingId}`);
    }

    getAthleteResults(athleteId: number, page?: number): Observable<Paging<Result>> {
        return this.http.get<Paging<Result>>(`${this.apiRoot}/athlete/${athleteId}/performances?page=${page}`);
    }

    getEvents(search: string): Observable<Paging<Meeting>> {
        return this.http.get<Paging<Meeting>>(`${this.meetingsUrl}?search=${search}`);
    }
}
