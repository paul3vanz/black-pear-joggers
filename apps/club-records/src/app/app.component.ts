import { Component, OnInit } from '@angular/core';
import { ClubRecord } from './models/club-record.model';
import { fromClubRecordsActions } from './+state/club-records.actions';
import { Store, State } from '@ngrx/store';
import { ClubRecordsPartialState } from './+state/club-records.reducer';
import { Observable } from 'rxjs';
import { clubRecordsQuery } from './+state/club-records.selectors';
import { searchQuery } from '@black-pear-joggers/search';
import { Router, ActivatedRoute, Params } from '@angular/router';
import { fromSearchActions } from 'libs/search/src/lib/+state/search.actions';
import { distinctUntilChanged, skip, take, filter } from 'rxjs/operators';

@Component({
  selector: 'bpj-root',
  templateUrl: './app.component.html',
  styleUrls: [ './app.component.scss' ],
})
export class AppComponent implements OnInit {
  clubRecords$: Observable<ClubRecord[]>;
  clubRecordsSelected$: Observable<ClubRecord>;
  clubRecordsCategories$: Observable<string[]>;
  clubRecordsGenders$: Observable<string[]>;
  clubRecordsLoaded$: Observable<boolean>;
  clubRecordsError$: Observable<boolean>;
  searchKeywords$: Observable<string>;
  showPace = false;

  ngOnInit() {
    this.store$.dispatch(new fromClubRecordsActions.Load());

    this.clubRecords$ = this.store$.select(clubRecordsQuery.getAllClubRecords);
    this.clubRecordsCategories$ = this.store$.select(clubRecordsQuery.getCategories);
    this.clubRecordsSelected$ = this.store$.select(clubRecordsQuery.getSelectedClubRecord);
    this.clubRecordsGenders$ = this.store$.select(clubRecordsQuery.getGenders);
    this.clubRecordsLoaded$ = this.store$.select(clubRecordsQuery.getLoaded);
    this.clubRecordsError$ = this.store$.select(clubRecordsQuery.getError);
    this.searchKeywords$ = this.store$.select(searchQuery.getKeywords);

    this.searchKeywords$.pipe(skip(1), distinctUntilChanged()).subscribe((keywords) => {
      this.router.navigate([], {
        relativeTo: this.route,
        queryParams: keywords ? { search: keywords } : null,
      });
    });

    this.route.queryParams.pipe(skip(1), take(1), filter((queryParams) => queryParams.search)).subscribe((queryParams: Params) => {
      this.store$.dispatch(new fromSearchActions.Search(queryParams.search));
    });
  }

  onQuery(record: ClubRecord) {
    this.store$.dispatch(new fromClubRecordsActions.Select(record));
  }

  onToggleFormat() {
    this.showPace = !this.showPace;
  }

  constructor(private store$: Store<any>, private router: Router, private route: ActivatedRoute) {}
}
