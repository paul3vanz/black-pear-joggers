import { ActivatedRoute } from '@angular/router';
import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import { Store } from '@ngrx/store';

import {
  athletesActions,
  athletesSelectors,
  LoadingState
} from '@black-pear-joggers/race-results-data-access';
import { rankingsActions } from 'libs/race-results-data-access/src/lib/+state/rankings.actions';
import * as resultsActions from '../../actions/results';

import * as rootReducer from '../../reducers';
import * as standardsReducer from '../../reducers/standards';
import * as resultsReducer from '../../reducers/results';
import * as rankingsReducer from 'libs/race-results-data-access/src/lib/+state/rankings.reducer';

import { rankingsSelectors } from '@black-pear-joggers/race-results-data-access';

import { Athlete } from '../../models/athlete';
import { Event } from '../../models/event';
import { Paging } from '../../models/paging';
import { Result } from '../../models/result';
import { Standard } from '../../models/standard';
import { Ranking } from '@black-pear-joggers/race-results-data-access';
import {
  ClubRecord,
  clubRecordsQuery,
  clubRecordsActions
} from '@black-pear-joggers/club-records-data-access';
import { YearRankingStats } from 'libs/race-results-data-access/src/lib/models/ranking-stats.model';

@Component({
  selector: 'bpj-athlete-page',
  templateUrl: './athlete-page.component.html',
  styleUrls: ['./athlete-page.component.css']
})
export class AthletePageComponent implements OnInit {
  athleteLoadingState$: Observable<LoadingState>;
  athlete$: Observable<Athlete>;
  resultsLoading$: Observable<boolean>;
  results$: Observable<Paging<Result>>;
  rankings$: Observable<Ranking[]>;
  rankingsStats$: Observable<YearRankingStats[]>;
  personalBests$: Observable<any>;
  standardsLoading$: Observable<boolean>;
  standards$: Observable<Standard[]>;
  events$: Observable<Paging<Event>>;
  recordsLoaded$: Observable<boolean>;
  records$: Observable<ClubRecord[]>;

  constructor(
    private route: ActivatedRoute,
    private store$: Store<rootReducer.State>
  ) {
    this.athleteLoadingState$ = this.store$.select(
      athletesSelectors.getLoadingState
    );
    this.athlete$ = this.store$.select(athletesSelectors.getSelectedRecord);

    this.athlete$.subscribe(console.log);

    this.resultsLoading$ = this.store$.select(resultsReducer.getLoading);
    this.results$ = this.store$.select(resultsReducer.getResults);
    this.rankings$ = this.store$.select(rankingsSelectors.selectAllRecords);
    this.rankingsStats$ = this.store$.select(rankingsSelectors.getStats);
    this.personalBests$ = this.store$.select(resultsReducer.getPersonalBests());

    this.recordsLoaded$ = this.store$.select(clubRecordsQuery.getLoaded);
    this.records$ = this.store$.select(
      clubRecordsQuery.getClubRecordsByAthlete(this.route.snapshot.params['id'])
    );

    this.standardsLoading$ = this.store$.select(
      store => store.standards.loading
    );
    this.standards$ = this.store$.select(standardsReducer.getStandards);
  }

  ngOnInit(): void {
    this.route.params.subscribe(({ id }) => {
      const athleteId = parseInt(id);

      this.store$.dispatch(athletesActions.load({ athleteId }));
      this.store$.dispatch(athletesActions.select({ athleteId }));
      this.store$.dispatch(rankingsActions.load({ athleteId }));
      this.store$.dispatch(clubRecordsActions.load());
      this.store$.dispatch(new resultsActions.GetAction(id));
    });
  }
}
