import { ActivatedRoute, Params } from '@angular/router';
import { Component, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import { switchMap } from 'rxjs/operators';

import { athletesActions } from '@black-pear-joggers/race-results-data-access';
import { Paging } from '../../models/paging';
import { Result } from '../../models/result';
import { ResultsService } from '../../services/results.service';

import * as rootReducer from '../../reducers';

@Component({
  selector: 'bpj-meeting-page',
  templateUrl: './meeting-page.component.html',
  styleUrls: ['./meeting-page.component.css']
})
export class MeetingPageComponent implements OnInit {
  results: Paging<Result>;

  constructor(
    private resultsService: ResultsService,
    private route: ActivatedRoute,
    private store$: Store<rootReducer.State>
  ) {}

  ngOnInit(): void {
    this.getResults();
  }

  getResults(): void {
    this.route.params
      .pipe(
        switchMap((params: Params) =>
          this.resultsService.getMeetingResults(params['date'], params['id'])
        )
      )
      .subscribe(results => (this.results = results));
  }

  selectAthlete(athleteId: number) {
    this.store$.dispatch(athletesActions.select({ athleteId }));
  }
}
