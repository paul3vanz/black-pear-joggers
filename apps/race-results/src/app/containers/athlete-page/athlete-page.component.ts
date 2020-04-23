import { ActivatedRoute, Params } from '@angular/router';
import { Component, OnInit } from '@angular/core';
import { Location } from '@angular/common';
import { Observable } from 'rxjs';
import { Store } from '@ngrx/store';

import * as athleteActions from '../../actions/athletes';
import * as rankingsActions from 'libs/race-results-data-access/src/lib/+state/rankings.actions';
import * as resultsActions from '../../actions/results';

import * as rootReducer from '../../reducers';
import * as standardsReducer from '../../reducers/standards';
import * as resultsReducer from '../../reducers/results';
import * as rankingsReducer from 'libs/race-results-data-access/src/lib/+state/rankings.reducer';

import * as rankingsSelectors from 'libs/race-results-data-access/src/lib/+state/rankings.selectors';

import { Athlete } from '../../models/athlete';
import { Event } from '../../models/event';
import { Paging } from '../../models/paging';
import { Result } from '../../models/result';
import { Standard } from '../../models/standard';
import { Ranking } from 'libs/race-results-data-access/src/lib/models/ranking.model';

@Component({
  selector: 'bpj-athlete-page',
  templateUrl: './athlete-page.component.html',
  styleUrls: ['./athlete-page.component.css']
})
export class AthletePageComponent implements OnInit {
  title = 'Athlete Details';
  athletesLoading$: Observable<boolean>;
  athlete$: Observable<Athlete>;
  resultsLoading$: Observable<boolean>;
  results$: Observable<Paging<Result>>;
  rankings$: Observable<Ranking[]>;
  personalBests$: Observable<any>;
  standardsLoading$: Observable<boolean>;
  standards$: Observable<Standard[]>;
  events$: Observable<Paging<Event>>;

  constructor(
    private route: ActivatedRoute,
    private location: Location,
    private store$: Store<rootReducer.State>
  ) {
    this.athletesLoading$ = this.store$.select(store => store.athletes.loading);
    this.athlete$ = this.store$.select(store => store.athletes.selected);

    this.resultsLoading$ = this.store$.select(resultsReducer.getLoading);
    this.results$ = this.store$.select(resultsReducer.getResults);
    this.rankings$ = this.store$.select(state => state.rankings.rankings);
    this.personalBests$ = this.store$.select(resultsReducer.getPersonalBests());

    this.standardsLoading$ = this.store$.select(
      store => store.standards.loading
    );
    this.standards$ = this.store$.select(standardsReducer.getStandards);
  }

  ngOnInit(): void {
    this.route.params.subscribe(({ id }) => {
      this.store$.dispatch(new athleteActions.GetAction(id));
      this.store$.dispatch(new resultsActions.GetAction(id));
      this.store$.dispatch(rankingsActions.loadAction({ athleteId: id }));
    });
  }
}
