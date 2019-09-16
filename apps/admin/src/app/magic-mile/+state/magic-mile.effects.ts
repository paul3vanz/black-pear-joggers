import { Injectable } from '@angular/core';
import { Effect, Actions } from '@ngrx/effects';
import { DataPersistence } from '@nrwl/nx';

import { MagicMilePartialState } from './magic-mile.reducer';
import {
  LoadAthletes,
  AthletesLoaded,
  AthletesLoadError,
  MagicMileActionTypes
} from './magic-mile.actions';
import { MagicMileService } from '@black-pear-joggers/magic-mile-data-access';
import { map } from 'rxjs/operators';

@Injectable()
export class MagicMileEffects {
  @Effect()
  loadMagicMile$ = this.dataPersistence.fetch(
    MagicMileActionTypes.LoadAthletes,
    {
      run: (action: LoadAthletes, state: MagicMilePartialState) => {
        return this.magicMileService.searchAthletes(action.athleteName).pipe(
          map((results) => {
            return new AthletesLoaded(results);
          })
        );
      },

      onError: (action: LoadAthletes, error) => {
        console.error('Error', error);
        return new AthletesLoadError(error);
      }
    }
  );

  constructor(
    private actions$: Actions,
    private dataPersistence: DataPersistence<MagicMilePartialState>,
    private magicMileService: MagicMileService
  ) {}
}
