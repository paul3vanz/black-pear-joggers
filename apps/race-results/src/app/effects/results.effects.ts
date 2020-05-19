import { Injectable } from '@angular/core';
import { Actions, Effect, ofType } from '@ngrx/effects';
import { of } from 'rxjs';
import { catchError, switchMap, map } from 'rxjs/operators';
import { ResultsService } from '../services/results.service';
import * as eventsActions from '..//actions/events';
import { resultsActions } from 'libs/race-results-data-access/src/lib/+state/results.actions';

@Injectable()
export class ResultsEffects {
  @Effect()
  loadResults$ = this.actions$.pipe(
    ofType(resultsActions.load),
    switchMap((action) => this.resultsService.getAthleteResults(action.athleteId, action.page)),
    map((results) => resultsActions.loadSuccess({ results }))
  );

  // TODO: Move into search effects
  @Effect()
  searchEvents$ = this.actions$.pipe(
    ofType(eventsActions.SEARCH),
    switchMap((action: eventsActions.SearchAction) =>
      this.resultsService.getEvents(action.payload).pipe(
        map((events) => new eventsActions.SearchSuccessAction(events)),
        catchError(() => of(new eventsActions.SearchFailAction()))
      )
    )
  );

  constructor(private actions$: Actions, private resultsService: ResultsService) {}
}
