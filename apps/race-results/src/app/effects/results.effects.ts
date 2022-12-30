import * as eventsActions from '../actions/meetings';
import { Actions, Effect, ofType } from '@ngrx/effects';
import { catchError, map, switchMap } from 'rxjs/operators';
import { Injectable } from '@angular/core';
import { of } from 'rxjs';
import { ResultsService } from '../services/results.service';
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

    constructor(private actions$: Actions, private resultsService: ResultsService) { }
}
