import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Standard } from '../models/standard';

@Injectable()
export class StandardsService {
    standardsUrl = 'https://bpj.org.uk/api/public/index.php/standards';

    constructor(private http: HttpClient) { }

    getStandards(gender: string, category: string): Observable<Standard[]> {
        return this.http.get<Standard[]>(`${this.standardsUrl}/${gender}/${category}`);
    }
}
