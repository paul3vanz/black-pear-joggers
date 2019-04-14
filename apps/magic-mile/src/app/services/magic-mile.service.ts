import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { map } from 'rxjs/operators';
import { MagicMile } from '../models/magic-mile.model';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class MagicMileService {
  private API_PATH = '';
  private KEY_SEARCH = 'bpj.magic-mile.search';

  constructor(private http: HttpClient) {}

  fetchResults(): Observable<MagicMile[]> {
    console.log(this.http);
    return this.http
      .get('https://bpj.org.uk/api/public/index.php/magicmile')
      .pipe(map(response => response.json() as Paging<Athlete>));
    return this.http
      .get('https://bpj.org.uk/api/public/index.php/magicmile')
      .pipe(
        map(response => {
          console.log('fetched');
          return response.map(result => {
            return {
              ...result,
              location: result.location
                .replace('Magic Mile (', '')
                .replace(')', '')
            };
          });
        })
      );
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
