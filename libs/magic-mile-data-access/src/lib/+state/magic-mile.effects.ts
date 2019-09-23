import { createEffect, Actions, ofType } from '@ngrx/effects';
import { Injectable } from '@angular/core';
import { catchError, map, mergeMap } from 'rxjs/operators';

import { MagicMileService } from '../services/magic-mile.service';
import * as magicMileActions from './magic-mile.actions';
import { EMPTY } from 'rxjs';

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

  constructor(
    private actions$: Actions,
    private magicMileService: MagicMileService
  ) {}
}
