import { createFeatureSelector, createSelector } from '@ngrx/store';

import { athletesReducer } from './athletes.reducer';

export namespace athletesSelectors {
  export const getState = createFeatureSelector<
    any,
    athletesReducer.AthletesState
  >(athletesReducer.ATHLETES_FEATURE_KEY);

  export const getAllRecords = createSelector(
    getState,
    (state: athletesReducer.AthletesState) => state.records
  );

  export const getSelectedRecord = createSelector(
    getState,
    (state: athletesReducer.AthletesState) => {
      return state.records.find(record => {
        return record.athlete_id === state.selected;
      });
    }
  );

  export const getLoadingState = createSelector(
    getState,
    (state: athletesReducer.AthletesState) => state.loadingState
  );
}
