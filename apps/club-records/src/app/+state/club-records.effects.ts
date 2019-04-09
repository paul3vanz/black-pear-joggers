import { Injectable } from '@angular/core';
import { Effect, Actions, ofType } from '@ngrx/effects';
import { DataPersistence } from '@nrwl/nx';

import { ClubRecordsPartialState } from './club-records.reducer';
import {
  Load,
  Loaded,
  LoadError,
  SendQuery,
  ClubRecordsActionTypes,
  fromClubRecordsActions,
  SendQuerySuccess,
  SendQueryError,
} from './club-records.actions';
import { ClubRecordsService } from '../services/club-records.service';
import { map, concatMap, catchError, switchMap } from 'rxjs/operators';
import { of } from 'rxjs';

@Injectable()
export class ClubRecordsEffects {
  @Effect()
  loadClubRecords$ = this.dataPersistence.fetch(ClubRecordsActionTypes.Load, {
    run: (action: Load, state: ClubRecordsPartialState) => {
      return this.clubRecordsService.fetch().pipe(
        map((records) => {
          return new Loaded(records);
        })
      );
    },

    onError: (action: Load, error) => {
      console.error('Error', error);
      return new LoadError(error);
    },
  });

  @Effect()
  sendQuery$ = this.actions$.pipe(
    ofType(ClubRecordsActionTypes.SendQuery),
    switchMap((action: SendQuery) => {
      return this.clubRecordsService.sendQuery(action.record, action.reason).pipe(
        map((response) => new SendQuerySuccess(response)),
        catchError(() => {
          return of(new SendQueryError(action));
        })
      );
    })
  );

  constructor(
    private actions$: Actions,
    private dataPersistence: DataPersistence<ClubRecordsPartialState>,
    private clubRecordsService: ClubRecordsService
  ) {}
}
