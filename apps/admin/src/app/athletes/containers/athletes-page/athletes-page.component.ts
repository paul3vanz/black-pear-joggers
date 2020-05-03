import { Component, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import {
  athletesActions,
  LoadingState,
  athletesSelectors,
  Athlete
} from '@black-pear-joggers/race-results-data-access';
import { Observable } from 'rxjs';

@Component({
  selector: 'bpj-athletes-page',
  templateUrl: './athletes-page.component.html',
  styleUrls: ['./athletes-page.component.scss']
})
export class AthletesPageComponent implements OnInit {
  loadingState$: Observable<LoadingState>;
  athletes$: Observable<Athlete[]>;

  constructor(private store$: Store<any>) {}

  ngOnInit() {
    this.store$.dispatch(athletesActions.load({}));

    this.loadingState$ = this.store$.select(
      athletesSelectors.selectLoadingState
    );

    this.athletes$ = this.store$.select(athletesSelectors.selectAllRecords);
  }
}
