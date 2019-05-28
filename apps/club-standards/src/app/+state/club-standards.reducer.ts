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
  claim: {
    loading: boolean;
    loaded: boolean;
    error?: any;
  };
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
  claim: {
    loading: false,
    loaded: false,
    error: null,
  },
};

export function clubStandardsReducer(state: ClubStandardsState = initialState, action: ClubStandardsAction): ClubStandardsState {
  switch (action.type) {
    case ClubStandardsActionTypes.LoadClubStandards: {
      return {
        ...state,
        list: [],
        loaded: false,
        error: false,
      };
    }
    case ClubStandardsActionTypes.ClubStandardsLoadError: {
      return {
        ...state,
        list: [],
        loaded: true,
        error: false,
      };
    }
    case ClubStandardsActionTypes.ClubStandardsLoaded: {
      return {
        ...state,
        list: action.payload,
        activeGender: action.payload[0].gender,
        activeCategory: action.payload[0].category,
        loaded: true,
        error: false,
      };
    }
    case ClubStandardsActionTypes.ClubStandardsSetGender: {
      return {
        ...state,
        activeGender: action.gender,
      };
    }
    case ClubStandardsActionTypes.ClubStandardsSetCategory: {
      return {
        ...state,
        activeCategory: action.category,
      };
    }
    case ClubStandardsActionTypes.ClubStandardsClaimSubmit: {
      return {
        ...state,
        claim: {
          loading: true,
          loaded: false,
        },
      };
    }
    case ClubStandardsActionTypes.ClubStandardsClaimSubmitSuccess: {
      return {
        ...state,
        claim: {
          loading: false,
          loaded: true,
        },
      };
    }
    case ClubStandardsActionTypes.ClubStandardsClaimSubmitError: {
      return {
        ...state,
        claim: {
          loading: false,
          loaded: false,
          error: true,
        },
      };
    }
  }
  return state;
}
