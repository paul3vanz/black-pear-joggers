import { Actions, createEffect, ofType } from '@ngrx/effects';
import { catchError, map, mergeMap } from 'rxjs/operators';
import { Injectable } from '@angular/core';
import { EMPTY, of } from 'rxjs';

import { MagicMileService } from '../services/magic-mile.service';
import * as magicMileActions from './magic-mile.actions';
import { MagicMile } from '../models/magic-mile.model';

@Injectable()
export class MagicMileEffects {
  loadResults$ = createEffect(() => this.actions$
    .pipe(
      ofType(magicMileActions.loadResults),
      mergeMap(() => this.magicMileService.fetchResults()
        .pipe(
          map(results => magicMileActions.loadResultsSuccess({ results })),
          catchError(() => EMPTY)
        )
      )
    )
  );

  deleteResults$ = createEffect(() => this.actions$
    .pipe(
      ofType(magicMileActions.deleteResult),
      map(action => action.result),
      mergeMap((result) => this.magicMileService.delete(result)
        .pipe(
          map((resultId) => magicMileActions.deleteResultSuccess({ resultId })),
          catchError(() => EMPTY)
        )
      )
    )
  );

  createResult$ = createEffect(() => this.actions$
    .pipe(
      ofType(magicMileActions.createResult),
      map(action => action.result),
      mergeMap((result) => this.magicMileService.create(this.mapResultToPayload(result))
        .pipe(
          map((result) => magicMileActions.createResultSuccess({ result })),
          catchError(() => EMPTY)
        )
      )
    )
  );

  private mapResultToPayload(result: MagicMile): any {
    return {
      actual_time: result.actualTime,
      actual_time_parsed: result.actualTimeParsed,
      athlete_id: result.athleteId,
      category: result.category,
      date: result.date,
      first_name: result.firstName,
      gender: result.gender,
      last_name: result.lastName,
      location: result.location,
      predicted_time: result.predictedTime,
      predicted_time_parsed: result.predictedTimeParsed,
    };
  }

  constructor(
    private actions$: Actions,
    private magicMileService: MagicMileService
  ) {}
}
