import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { MagicMile } from '../models/magic-mile.model';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Athlete } from 'apps/race-results/src/app/models/athlete';

@Injectable({
  providedIn: 'root'
})
export class MagicMileService {
  private API_PATH = '';
  private KEY_SEARCH = 'bpj.magic-mile.search';

  constructor(private http: HttpClient) {}

  fetchResults(): Observable<MagicMile[]> {
    return this.http
      .get<MagicMile[]>('https://bpj.org.uk/api/public/index.php/magicmile')
      .pipe(
        map(results => {
          return results.map(result => {
            return {
              ...result,
              location: result.location.replace(
                new RegExp(/Magic Mile \((.*)?\)/),
                '$1'
              )
            };
          });
        })
      );
  }

  searchAthletes(searchTerm: string) {
    return this.http.get<Athlete[]>(`https://bpj.org.uk/api/public/index.php/athletes?search=${searchTerm}`);
  }

  setSearch(keywords) {
    localStorage.setItem(this.KEY_SEARCH, keywords);
  }

  getSearch(): string {
    return localStorage.getItem(this.KEY_SEARCH);
  }

  create(magicMile: MagicMile) {
    return this.http.post(this.API_PATH, magicMile);
  }
}
