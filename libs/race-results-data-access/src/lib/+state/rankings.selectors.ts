import * as rankingsReducer from './rankings.reducer';
import { createFeatureSelector, State, createSelector } from '@ngrx/store';

export const selectState = createFeatureSelector<any, rankingsReducer.State>(
  rankingsReducer.FEATURE_KEY
);

export const selectAllRecords = createSelector(
  selectState,
  (state: rankingsReducer.State) => state.records
);

export const selectLoading = createSelector(
  selectState,
  (state: rankingsReducer.State) => state.loadingState
);

export const rankingsSelectors = {
  selectState,
  selectAllRecords,
  selectLoading
};
