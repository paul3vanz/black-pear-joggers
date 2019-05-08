import { Injectable } from '@angular/core';
import { Effect, Actions, ofType } from '@ngrx/effects';
import { DataPersistence } from '@nrwl/nx';

import { MagicMilePartialState } from './magic-mile.reducer';
import { Load, Loaded, LoadError, MagicMileActionTypes, Search } from './magic-mile.actions';
import { switchMap, map } from 'rxjs/operators';
import { empty } from 'rxjs';
import { MagicMileService } from '../services/magic-mile.service';

@Injectable()
export class MagicMileEffects {
  @Effect()
  loadMagicMile$ = this.dataPersistence.fetch(MagicMileActionTypes.Load, {
    run: (action: Load, state: MagicMilePartialState) => {
      return this.magicMileService.fetchResults().pipe(
        map((results) => {
          return new Loaded(results);
        })
      );
    },

    onError: (action: Load, error) => {
      console.error('Error', error);
      return new LoadError(error);
    },
  });

  @Effect()
  searchMagicMile$ = this.actions$.ofType(MagicMileActionTypes.Search).pipe(
    switchMap((action: Search) => {
      this.magicMileService.setSearch(action.payload);
      return empty();
    })
  );

  constructor(
    private actions$: Actions,
    private dataPersistence: DataPersistence<MagicMilePartialState>,
    private magicMileService: MagicMileService
  ) {}
}
