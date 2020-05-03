import * as athletesReducer from './athletes.reducer';
import { createFeatureSelector, State, createSelector } from '@ngrx/store';

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
      console.log(
        record.athlete_id,
        state.selected,
        record.athlete_id === state.selected
      );
      return record.athlete_id === state.selected;
    });
  }
);

export const getLoadingState = createSelector(
  getState,
  (state: athletesReducer.AthletesState) => state.loadingState
);

export const athletesSelectors = {
  getState,
  getAllRecords,
  getSelectedRecord,
  getLoadingState
};
