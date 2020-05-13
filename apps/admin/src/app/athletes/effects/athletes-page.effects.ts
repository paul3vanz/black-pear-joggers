import { Injectable } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { of } from 'rxjs';
import { map, catchError, switchMap, tap, filter } from 'rxjs/operators';

import {
  RankingsService,
  athletesActions,
  rankingsActions
} from '@black-pear-joggers/race-results-data-access';

@Injectable()
export class AthletesPageEffects {
  selectAthlete$ = createEffect(() =>
    this.actions$.pipe(
      ofType(athletesActions.select),
      map(({ athleteId }) => rankingsActions.load({ athleteId }))
    )
  );

  constructor(
    private actions$: Actions,
    private rankingsService: RankingsService
  ) {}
}
