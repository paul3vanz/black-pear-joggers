import { ClubStandardsAction, ClubStandardsActionTypes } from './club-standards.actions';
import { Standard } from '../models/standard.model';

export const CLUBSTANDARDS_FEATURE_KEY = 'clubStandards';

/**
 * Interface for the 'ClubStandards' data used in
 *  - ClubStandardsState, and
 *  - clubStandardsReducer
 *
 *  Note: replace if already defined in another module
 */

export interface ClubStandardsState {
  list: Standard[]; // list of ClubStandards; analogous to a sql normalized table
  activeGender: string;
  activeCategory: string;
  loaded: boolean; // has the ClubStandards list been loaded
  error?: any; // last none error (if any)
}

export interface ClubStandardsPartialState {
  readonly [CLUBSTANDARDS_FEATURE_KEY]: ClubStandardsState;
}

export const initialState: ClubStandardsState = {
  list: [],
  activeGender: 'M',
  activeCategory: 'SEN',
  loaded: false,
  error: false,
};

export function clubStandardsReducer(state: ClubStandardsState = initialState, action: ClubStandardsAction): ClubStandardsState {
  switch (action.type) {
    case ClubStandardsActionTypes.LoadClubStandards: {
      state = {
        ...state,
        list: [],
        loaded: false,
        error: false,
      };
      break;
    }
    case ClubStandardsActionTypes.ClubStandardsLoadError: {
      state = {
        ...state,
        list: [],
        loaded: true,
        error: false,
      };
    }
    case ClubStandardsActionTypes.ClubStandardsLoaded: {
      state = {
        ...state,
        list: action.payload,
        activeGender: action.payload[0].gender,
        activeCategory: action.payload[0].category,
        loaded: true,
        error: false,
      };
      break;
    }
    case ClubStandardsActionTypes.ClubStandardsSetGender: {
      state = {
        ...state,
        activeGender: action.gender,
      };
      break;
    }
    case ClubStandardsActionTypes.ClubStandardsSetCategory: {
      state = {
        ...state,
        activeCategory: action.category,
      };
      break;
    }
  }
  return state;
}
