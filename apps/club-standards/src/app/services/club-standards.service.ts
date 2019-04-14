import { Injectable } from '@angular/core';
import { Standard } from '../models/standard.model';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root',
})
export class ClubStandardsService {
  standardsUrl = '//bpj.org.uk/api/public/index.php/standards';

  constructor(private http: HttpClient) {}

  getStandards(gender: string, category: string): Observable<Standard[]> {
    return this.http.get<Standard[]>(`${this.standardsUrl}/${gender}/${category}`);
  }
}
