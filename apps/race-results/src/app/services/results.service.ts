import { delay, map } from 'rxjs/operators';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { Event } from '../models/event';
import { Result } from '../models/result';
import { Paging } from '../models/paging';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class ResultsService {
  apiRoot = '//bpj.org.uk/api/public/index.php';
  resultsUrl = '//bpj.org.uk/api/public/index.php/performances?onlyAwards=0&fromDate=2017-01-01';
  athleteResultsUrlRoot = '//bpj.org.uk/api/public/index.php/performances?onlyAwards=0';
  performancesUrl = '//bpj.org.uk/api/public/index.php/performances';

  constructor(private http: HttpClient) {}

  getResults(): Observable<Result[]> {
    return this.http.get<Result[]>(this.resultsUrl);
  }

  getMeetingResults(date: string, meetingId: string): Observable<Paging<Result>> {
    return this.http.get<Paging<Result>>(`${this.performancesUrl}/${date}/${meetingId}`);
  }

  getAthleteResults(athleteId: string, page?: number): Observable<Paging<Result>> {
    return this.http.get<Paging<Result>>(`${this.apiRoot}/athlete/${athleteId}/performances?page=${page}`);
  }

  getEvents(search: string): Observable<Paging<Event>> {
    return this.http.get<Paging<Event>>(`${this.performancesUrl}?search=${search}`);
  }
}
