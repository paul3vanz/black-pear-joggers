import { Injectable } from '@angular/core';
import { Effect } from '@ngrx/effects';
import { DataPersistence } from '@nrwl/nx';

import { MagicMilePartialState } from './magic-mile.reducer';
import { Load, Loaded, LoadError, MagicMileActionTypes } from './magic-mile.actions';
import { map } from 'rxjs/operators';
import { MagicMileService } from '../services/magic-mile.service';

@Injectable()
export class MagicMileEffects {
  @Effect()
  loadMagicMile$ = this.dataPersistence.fetch(MagicMileActionTypes.Load, {
    run: () => {
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

  constructor(private dataPersistence: DataPersistence<MagicMilePartialState>, private magicMileService: MagicMileService) {}
}
