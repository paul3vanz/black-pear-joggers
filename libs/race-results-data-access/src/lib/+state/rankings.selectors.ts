import * as rankingsReducer from './rankings.reducer';
import { createFeatureSelector, State, createSelector } from '@ngrx/store';

export const selectRankings = createFeatureSelector<any, rankingsReducer.State>(
  rankingsReducer.FEATURE_KEY
);

export const selectLoading = createSelector(
  selectRankings,
  (state: rankingsReducer.State) => state.rankings
);
