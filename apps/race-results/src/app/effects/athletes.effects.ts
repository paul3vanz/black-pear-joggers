import { Injectable } from '@angular/core';
import { Actions, Effect } from '@ngrx/effects';
import { Action } from '@ngrx/store';
import { Observable, of, empty } from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  switchMap,
  map,
} from 'rxjs/operators';
import {
  AthletesActionTypes,
  GetAction,
  GetSuccessAction,
  SearchAction,
  SearchSuccessAction,
  SearchFailAction,
  SelectAction,
} from '../actions/athletes';
import { GetAction as GetStandardsAction } from '../actions/standards';
import { AthletesService } from '../services/athletes.service';

@Injectable()
export class AthletesEffects {
  @Effect()
  getAthlete$ = this.actions$
    .ofType(AthletesActionTypes.GET)
    .pipe(
      switchMap((action: GetAction) =>
        this.athletesService
          .getAthlete(action.payload)
          .pipe(map(athlete => new GetSuccessAction(athlete)))
      )
    );

  @Effect()
  getAthleteSuccess$ = this.actions$
    .ofType(AthletesActionTypes.GET_SUCCESS)
    .pipe(
      switchMap((action: GetSuccessAction) => {
        return of(
          new GetStandardsAction(action.payload.gender, action.payload.category)
        );
      })
    );

  @Effect()
  searchAthletes$ = this.actions$.ofType(AthletesActionTypes.SEARCH).pipe(
    switchMap((action: SearchAction) =>
      this.athletesService.getAthletes(action.payload).pipe(
        map(athletes => new SearchSuccessAction(athletes)),
        catchError(() => of(new SearchFailAction()))
      )
    )
  );

  @Effect()
  selectAthlete$ = this.actions$.ofType(AthletesActionTypes.SELECT).pipe(
    switchMap((action: SelectAction) => {
      this.athletesService.selectAthlete(action.payload);
      return empty();
    })
  );

  constructor(
    private actions$: Actions,
    private athletesService: AthletesService
  ) {}
}
