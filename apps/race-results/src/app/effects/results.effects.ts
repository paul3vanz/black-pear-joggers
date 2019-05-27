import { Injectable } from '@angular/core';
import { Actions, Effect } from '@ngrx/effects';
import { of } from 'rxjs';
import { catchError, switchMap, map } from 'rxjs/operators';
import { ResultsActionsTypes, GetAction, GetSuccessAction } from '../actions/results';
import { ResultsService } from '../services/results.service';
import * as eventsActions from '..//actions/events';

@Injectable()
export class ResultsEffects {
  @Effect()
  loadResults$ = this.actions$
    .ofType(ResultsActionsTypes.GET)
    .pipe(
      switchMap((action: GetAction) => this.resultsService.getAthleteResults(action.payload.athleteId, action.payload.page)),
      map((results) => new GetSuccessAction(results))
    );

  // TODO: Move into search effects
  @Effect()
  searchEvents$ = this.actions$
    .ofType(eventsActions.SEARCH)
    .pipe(
      switchMap((action: eventsActions.SearchAction) =>
        this.resultsService
          .getEvents(action.payload)
          .pipe(map((events) => new eventsActions.SearchSuccessAction(events)), catchError(() => of(new eventsActions.SearchFailAction())))
      )
    );

  constructor(private actions$: Actions, private resultsService: ResultsService) {}
}