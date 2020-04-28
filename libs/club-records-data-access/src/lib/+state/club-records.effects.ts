import { Injectable } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { of } from 'rxjs';
import { map, concatMap, catchError, switchMap } from 'rxjs/operators';

import { clubRecordsActions } from './club-records.actions';
import { ClubRecordsService } from '../services/club-records.service';

@Injectable()
export class ClubRecordsEffects {
  loadClubRecords$ = createEffect(() =>
    this.actions$.pipe(
      ofType(clubRecordsActions.load),
      switchMap(() =>
        this.clubRecordsService.fetch().pipe(
          map(records => clubRecordsActions.loaded({ records })),
          catchError(error => of(clubRecordsActions.loadError({ error })))
        )
      )
    )
  );

  sendQuery$ = createEffect(() =>
    this.actions$.pipe(
      ofType(clubRecordsActions.sendQuery),
      concatMap(action => {
        return this.clubRecordsService.sendQuery(action.clubRecordQuery).pipe(
          map(() => clubRecordsActions.sendQuerySuccess()),
          catchError(() => of(clubRecordsActions.sendQueryError()))
        );
      })
    )
  );

  sendQuerySuccess$ = createEffect(() =>
    this.actions$.pipe(
      ofType(clubRecordsActions.sendQuerySuccess),
      map(() => clubRecordsActions.load())
    )
  );

  constructor(
    private actions$: Actions,
    private clubRecordsService: ClubRecordsService
  ) {}
}
