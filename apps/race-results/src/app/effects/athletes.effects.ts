import { Injectable } from '@angular/core';
import { Actions, Effect, ofType } from '@ngrx/effects';
import { Action } from '@ngrx/store';
import { Observable, of, empty } from 'rxjs';
import { catchError, debounceTime, distinctUntilChanged, switchMap, map } from 'rxjs/operators';
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
  getAthlete$ = this.actions$.pipe(
    ofType(AthletesActionTypes.GET),
    switchMap((action: GetAction) => this.athletesService.getAthlete(action.payload).pipe(map((athlete) => new GetSuccessAction(athlete))))
  );

  @Effect()
  getAthleteSuccess$ = this.actions$.pipe(
    ofType(AthletesActionTypes.GET_SUCCESS),
    switchMap((action: GetSuccessAction) => {
      return of(new GetStandardsAction(action.payload.gender, action.payload.category));
    })
  );

  @Effect()
  searchAthletes$ = this.actions$
  .pipe(
      ofType(AthletesActionTypes.SEARCH),
      switchMap((action: SearchAction) =>
        this.athletesService
          .getAthletes(action.payload)
          .pipe(map((athletes) => new SearchSuccessAction(athletes)), catchError(() => of(new SearchFailAction())))
      )
    );

  @Effect()
  selectAthlete$ = this.actions$.pipe(
    ofType(AthletesActionTypes.SELECT),
    switchMap((action: SelectAction) => {
      this.athletesService.selectAthlete(action.payload);
      return empty();
    })
  );

  constructor(private actions$: Actions, private athletesService: AthletesService) {}
}
