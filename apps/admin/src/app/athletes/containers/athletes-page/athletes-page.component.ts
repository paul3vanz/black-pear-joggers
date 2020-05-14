import { Component, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import {
  athletesActions,
  LoadingState,
  athletesSelectors,
  Athlete,
  rankingsSelectors,
  Ranking
} from '@black-pear-joggers/race-results-data-access';
import { Observable } from 'rxjs';

@Component({
  selector: 'bpj-athletes-page',
  templateUrl: './athletes-page.component.html',
  styleUrls: ['./athletes-page.component.scss']
})
export class AthletesPageComponent implements OnInit {
  loadingState$: Observable<LoadingState>;
  athlete$: Observable<Athlete>;
  athletes$: Observable<Athlete[]>;
  rankings$: Observable<Ranking[]>;
  rankingsLoadingState$: Observable<LoadingState>;

  constructor(private store$: Store<any>) {}

  ngOnInit() {
    this.store$.dispatch(athletesActions.load({}));

    this.athlete$ = this.store$.select(athletesSelectors.getSelectedRecord);
    this.athletes$ = this.store$.select(athletesSelectors.getAllRecords);
    this.loadingState$ = this.store$.select(athletesSelectors.getLoadingState);
    this.rankings$ = this.store$.select(rankingsSelectors.selectAllRecords);
    this.rankingsLoadingState$ = this.store$.select(
      rankingsSelectors.selectLoading
    );
  }

  onSelectAthlete(athleteId: number) {
    this.store$.dispatch(athletesActions.select({ athleteId }));
  }
}
