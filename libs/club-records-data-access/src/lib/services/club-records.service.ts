import { ClubRecord } from '../models/club-record.model';
import { ClubRecordQuery } from '../models/club-record-query.model';
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';

@Injectable({
    providedIn: 'root'
})
export class ClubRecordsService {
    constructor(private http: HttpClient) { }

    sendQuery(clubRecordQuery: ClubRecordQuery): Observable<void> {
        return this.http.post<void>(
            'https://bpj.org.uk/api/public/index.php/records/query',
            clubRecordQuery
        );
    }

    fetch(): Observable<ClubRecord[]> {
        return this.http
            .get<ClubRecord[]>('https://bpj.org.uk/api/public/index.php/records')
            .pipe(
                map((clubRecords: ClubRecord[]) => {
                    return clubRecords.filter(
                        (clubRecord: ClubRecord) => clubRecord.gender
                    );
                })
            );
    }
}
