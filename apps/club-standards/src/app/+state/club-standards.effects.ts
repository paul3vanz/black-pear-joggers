import { Injectable } from '@angular/core';
import { Effect, Actions, ofType } from '@ngrx/effects';
import { DataPersistence } from '@nrwl/angular';

import { ClubStandardsPartialState } from './club-standards.reducer';
import {
  LoadClubStandards,
  ClubStandardsLoaded,
  ClubStandardsLoadError,
  ClubStandardsActionTypes,
  ClubStandardsSetGender,
  ClubStandardsSetCategory,
  ClubStandardsClaimSubmit,
  ClubStandardsClaimSubmitError,
  ClubStandardsClaimSubmitSuccess,
} from './club-standards.actions';
import { ClubStandardsService } from '../services/club-standards.service';
import { map, withLatestFrom, switchMap, catchError } from 'rxjs/operators';
import { clubStandardsQuery } from './club-standards.selectors';
import { Store } from '@ngrx/store';
import { of } from 'rxjs';

@Injectable()
export class ClubStandardsEffects {
  @Effect()
  loadClubStandards$ = this.dataPersistence.fetch(ClubStandardsActionTypes.LoadClubStandards, {
    run: (action: LoadClubStandards, state: ClubStandardsPartialState) => {
      return this.clubStandardsService.getStandards(action.gender, action.category).pipe(
        map((standards) => {
          return new ClubStandardsLoaded(standards);
        })
      );
    },

    onError: (action: LoadClubStandards, error) => {
      console.error('Error', error);
      return new ClubStandardsLoadError(error);
    },
  });

  @Effect()
  selectGender$ = this.actions$.pipe(
    ofType(ClubStandardsActionTypes.ClubStandardsSetGender),
    map((action: ClubStandardsSetGender) => action.gender),
    withLatestFrom(this.store$.select(clubStandardsQuery.getActiveCategory)),
    map(([gender, category]) => {
      return new LoadClubStandards(gender, category);
    })
  );

  @Effect()
  selectCategory$ = this.actions$.pipe(
    ofType(ClubStandardsActionTypes.ClubStandardsSetCategory),
    map((action: ClubStandardsSetCategory) => action.category),
    withLatestFrom(this.store$.select(clubStandardsQuery.getActiveGender)),
    map(([category, gender]) => {
      return new LoadClubStandards(gender, category);
    })
  );

  @Effect()
  submitClaim$ = this.actions$.pipe(
    ofType(ClubStandardsActionTypes.ClubStandardsClaimSubmit),
    map((action: ClubStandardsClaimSubmit) => action.payload),
    switchMap((formData) => {
      const awardClaim = this.clubStandardsService.convertFormModelToApiModel(formData);

      return this.clubStandardsService.submitClaim(awardClaim).pipe(
        map((payload) => {
          return new ClubStandardsClaimSubmitSuccess(payload);
        }),
        catchError((error) => {
          return of(new ClubStandardsClaimSubmitError(error));
        })
      );
    })
  );

  constructor(
    private actions$: Actions,
    private dataPersistence: DataPersistence<ClubStandardsPartialState>,
    private clubStandardsService: ClubStandardsService,
    private store$: Store<any>
  ) {}
}
