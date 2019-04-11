import { Component, OnInit } from '@angular/core';
import { ClubRecord } from './models/club-record.model';
import { fromClubRecordsActions } from './+state/club-records.actions';
import { Store, State } from '@ngrx/store';
import { ClubRecordsPartialState } from './+state/club-records.reducer';
import { Observable } from 'rxjs';
import { clubRecordsQuery } from './+state/club-records.selectors';
import { searchQuery } from '@black-pear-joggers/search';

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

  ngOnInit() {
    this.store$.dispatch(new fromClubRecordsActions.Load());

    this.clubRecords$ = this.store$.select(clubRecordsQuery.getAllClubRecords);
    this.clubRecordsCategories$ = this.store$.select(clubRecordsQuery.getCategories);
    this.clubRecordsSelected$ = this.store$.select(clubRecordsQuery.getSelectedClubRecord);
    this.clubRecordsGenders$ = this.store$.select(clubRecordsQuery.getGenders);
    this.clubRecordsLoaded$ = this.store$.select(clubRecordsQuery.getLoaded);
    this.clubRecordsError$ = this.store$.select(clubRecordsQuery.getError);
    this.searchKeywords$ = this.store$.select(searchQuery.getKeywords);
  }

  onQuery(record: ClubRecord) {
    this.store$.dispatch(new fromClubRecordsActions.Select(record));
  }

  constructor(private store$: Store<any>) {}
}
