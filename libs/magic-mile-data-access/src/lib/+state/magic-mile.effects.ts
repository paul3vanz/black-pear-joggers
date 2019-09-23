import { Actions, createEffect, ofType } from '@ngrx/effects';
import { catchError, map, mergeMap } from 'rxjs/operators';
import { Injectable } from '@angular/core';
import { EMPTY } from 'rxjs';

import { MagicMileService } from '../services/magic-mile.service';
import * as magicMileActions from './magic-mile.actions';
import { MagicMile } from '../models/magic-mile.model';

@Injectable()
export class MagicMileEffects {
  loadResults$ = createEffect(() => this.actions$.pipe(
    ofType(magicMileActions.loadResults),
    mergeMap(() => this.magicMileService.fetchResults()
      .pipe(
        map(results => magicMileActions.loadResultsSuccess({ results })),
        catchError(() => EMPTY),
      ))
    )
  );

  deleteResults$ = createEffect(() => this.actions$.pipe(
    ofType(magicMileActions.deleteResult),
    map(action => action.result),
    mergeMap((result) => this.magicMileService.delete(result)
      .pipe(
        map((resultId) => magicMileActions.deleteResultSuccess({ resultId })),
        catchError(() => EMPTY),
      ))
    )
  );

  constructor(
    private actions$: Actions,
    private magicMileService: MagicMileService
  ) {}
}
