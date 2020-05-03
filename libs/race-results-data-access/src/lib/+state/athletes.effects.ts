import { Injectable } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { of } from 'rxjs';
import { map, catchError, switchMap, tap, filter } from 'rxjs/operators';

import { AthletesService } from '../services/athletes.service';
import { athletesActions } from './athletes.actions';

@Injectable()
export class AthletesEffects {
  loadAthlete$ = createEffect(() =>
    this.actions$.pipe(
      ofType(athletesActions.load),
      filter(({ athleteId }) => !!athleteId),
      switchMap(({ athleteId }) =>
        this.athletesService.getAthlete(athleteId).pipe(
          map(athlete => athletesActions.loadSuccess({ athletes: [athlete] })),
          catchError(error => of(athletesActions.loadFailure({ error })))
        )
      )
    )
  );

  loadAthletes$ = createEffect(() =>
    this.actions$.pipe(
      ofType(athletesActions.load),
      filter(({ athleteId }) => !athleteId),
      switchMap(() =>
        this.athletesService.getAthletes('').pipe(
          map(athletes => athletesActions.loadSuccess({ athletes })),
          catchError(error => of(athletesActions.loadFailure({ error })))
        )
      )
    )
  );

  searchAthletes$ = createEffect(() =>
    this.actions$.pipe(
      ofType(athletesActions.search),
      switchMap(({ keywords }) => {
        return this.athletesService.getAthletes(keywords).pipe(
          map(athletes => athletesActions.loadSuccess({ athletes })),
          catchError(error => of(athletesActions.loadFailure({ error })))
        );
      })
    )
  );

  constructor(
    private actions$: Actions,
    private athletesService: AthletesService
  ) {}
}
