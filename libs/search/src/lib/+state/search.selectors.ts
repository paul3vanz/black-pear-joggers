import { createFeatureSelector, createSelector } from '@ngrx/store';
import { SEARCH_FEATURE_KEY, SearchState } from './search.reducer';

// Lookup the 'Search' feature state managed by NgRx
const getSearchState = createFeatureSelector<SearchState>(SEARCH_FEATURE_KEY);

const getKeywords = createSelector(getSearchState, (state: SearchState) => state.keywords);

export const searchQuery = {
  getKeywords,
};
