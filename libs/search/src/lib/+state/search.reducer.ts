import { SearchAction, SearchActionTypes } from './search.actions';

export const SEARCH_FEATURE_KEY = 'search';

/**
 * Interface for the 'Search' data used in
 *  - SearchState, and
 *  - searchReducer
 *
 *  Note: replace if already defined in another module
 */

export interface SearchState {
  keywords: string;
}

export interface SearchPartialState {
  readonly [SEARCH_FEATURE_KEY]: SearchState;
}

export const initialState: SearchState = {
  keywords: '',
};

export function searchReducer(state: SearchState = initialState, action: SearchAction): SearchState {
  switch (action.type) {
    case SearchActionTypes.Search: {
      state = {
        ...state,
        keywords: action.payload,
      };
      break;
    }
  }
  return state;
}
