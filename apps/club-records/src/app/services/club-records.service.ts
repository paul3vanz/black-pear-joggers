import { ClubRecord } from '../models/club-record.model';
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';

@Injectable({
    providedIn: 'root',
})
export class ClubRecordsService {
    constructor(private http: HttpClient) { }

    sendQuery(record: ClubRecord, reason: string, notes: string): Observable<any> {
        return this.http.post('https://bpj.org.uk/api/public/index.php/records/query', { record, reason, notes });
    }

    fetch(): Observable<ClubRecord[]> {
        return this.http.get<ClubRecord[]>('https://bpj.org.uk/api/public/index.php/records').pipe(
            map((clubRecords: ClubRecord[]) => {
                return clubRecords.filter((clubRecord: ClubRecord) => clubRecord.gender);
            })
        );
    }
}
