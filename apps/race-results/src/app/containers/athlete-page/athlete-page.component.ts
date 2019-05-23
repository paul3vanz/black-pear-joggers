import { ActivatedRoute, Params } from '@angular/router';
import { Component, OnInit } from '@angular/core';
import { Location } from '@angular/common';
import { Observable } from 'rxjs';
import { Store } from '@ngrx/store';
// import { take, withLatestFrom } from 'rxjs/operators';

import * as athleteActions from '../../actions/athletes';
import * as resultsActions from '../../actions/results';

import * as rootReducer from '../../reducers';
import * as standardsReducer from '../../reducers/standards';
import * as resultsReducer from '../../reducers/results';

import { Athlete } from '../../models/athlete';
import { Event } from '../../models/event';
import { Paging } from '../../models/paging';
import { Result } from '../../models/result';
import { Standard } from '../../models/standard';

@Component({
  selector: 'bpj-athlete-page',
  templateUrl: './athlete-page.component.html',
  styleUrls: [ './athlete-page.component.css' ],
})
export class AthletePageComponent implements OnInit {
  title = 'Athlete Details';
  athletesLoading$: Observable<boolean>;
  athlete$: Observable<Athlete>;
  resultsLoading$: Observable<boolean>;
  results$: Observable<Paging<Result>>;
  personalBests$: Observable<any>;
  standardsLoading$: Observable<boolean>;
  standards$: Observable<Standard[]>;
  events$: Observable<Paging<Event>>;

  constructor(private route: ActivatedRoute, private location: Location, private store$: Store<rootReducer.State>) {
    this.athletesLoading$ = this.store$.select((store) => store.athletes.loading);
    this.athlete$ = this.store$.select((store) => store.athletes.selected);

    this.resultsLoading$ = this.store$.select(resultsReducer.getLoading);
    this.results$ = this.store$.select(resultsReducer.getResults);
    this.personalBests$ = this.store$.select(resultsReducer.getPersonalBests());

    this.standardsLoading$ = this.store$.select((store) => store.standards.loading);
    this.standards$ = this.store$.select(standardsReducer.getStandards);
  }

  ngOnInit(): void {
    this.route.params.subscribe((params: Params) => {
      this.store$.dispatch(new athleteActions.GetAction(params['id']));
      this.store$.dispatch(new resultsActions.GetAction(params['id']));
    });
  }
}
