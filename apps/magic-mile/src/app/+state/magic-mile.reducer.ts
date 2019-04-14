import { MagicMileAction, MagicMileActionTypes } from './magic-mile.actions';

export const MAGICMILE_FEATURE_KEY = 'magicMile';

/**
 * Interface for the 'MagicMile' data used in
 *  - MagicMileState, and
 *  - magicMileReducer
 *
 *  Note: replace if already defined in another module
 */

/* tslint:disable:no-empty-interface */
export interface Entity {}

export interface MagicMileState {
  list: Entity[]; // list of MagicMile; analogous to a sql normalized table
  selectedId?: string | number; // which MagicMile record has been selected
  loaded: boolean; // has the MagicMile list been loaded
  error?: any; // last none error (if any)
  filter: {
    year: string;
    name: string;
  };
}

export interface MagicMilePartialState {
  readonly [MAGICMILE_FEATURE_KEY]: MagicMileState;
}

export const initialState: MagicMileState = {
  list: [],
  loaded: false,
  filter: {
    year: null,
    name: null
  }
};

export function magicMileReducer(
  state: MagicMileState = initialState,
  action: MagicMileAction
): MagicMileState {
  switch (action.type) {
    case MagicMileActionTypes.Loaded: {
      state = {
        ...state,
        list: action.payload,
        loaded: true
      };
      break;
    }
    case MagicMileActionTypes.Search: {
      state = {
        ...state,
        filter: {
          ...state.filter,
          name: action.payload
        }
      };
      break;
    }
    case MagicMileActionTypes.SetYear: {
      state = {
        ...state,
        filter: {
          ...state.filter,
          year: action.payload
        }
      };
    }
  }
  return state;
}
