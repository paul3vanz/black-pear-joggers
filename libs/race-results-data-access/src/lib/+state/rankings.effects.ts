import { Injectable } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { of } from 'rxjs';
import { map, mergeMap, catchError } from 'rxjs/operators';
import { RankingsService } from '../services/rankings.service';
import {
  loadAction,
  loadSuccessAction,
  loadFailureAction
} from './rankings.actions';

@Injectable()
export class RankingsEffects {
  loadRankings$ = createEffect(() =>
    this.actions$.pipe(
      ofType(loadAction),
      mergeMap(({ athleteId }) =>
        this.rankingsService.loadRankings(athleteId).pipe(
          map(rankings => {
            return loadSuccessAction({ rankings });
          }),
          catchError(() => of(loadFailureAction()))
        )
      )
    )
  );

  constructor(
    private actions$: Actions,
    private rankingsService: RankingsService
  ) {}
}
