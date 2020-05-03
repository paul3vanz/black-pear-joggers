import { Actions, createEffect, ofType } from '@ngrx/effects';
import { Injectable } from '@angular/core';
import { map, mergeMap, catchError } from 'rxjs/operators';
import { of } from 'rxjs';

import { rankingsActions } from './rankings.actions';
import { RankingsService } from '../services/rankings.service';

@Injectable()
export class RankingsEffects {
  loadRankings$ = createEffect(() =>
    this.actions$.pipe(
      ofType(rankingsActions.load),
      mergeMap(({ athleteId }) =>
        this.rankingsService.loadRankings(athleteId).pipe(
          map(rankings => {
            return rankingsActions.loadSuccess({ rankings });
          }),
          catchError(error => of(rankingsActions.loadFailure({ error })))
        )
      )
    )
  );

  constructor(
    private actions$: Actions,
    private rankingsService: RankingsService
  ) {}
}
