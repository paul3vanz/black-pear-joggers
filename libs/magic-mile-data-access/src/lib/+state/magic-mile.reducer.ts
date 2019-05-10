import { MagicMileAction, MagicMileActionTypes } from './magic-mile.actions';
import { MagicMile } from '../models/magic-mile.model';

export const MAGICMILE_FEATURE_KEY = 'magicMile';

export interface MagicMileState {
  list: MagicMile[]; // list of MagicMile; analogous to a sql normalized table
  selectedId?: string | number; // which MagicMile record has been selected
  loaded: boolean; // has the MagicMile list been loaded
  error?: any; // last none error (if any)
}

export interface MagicMilePartialState {
  readonly [MAGICMILE_FEATURE_KEY]: MagicMileState;
}

export const initialState: MagicMileState = {
  list: [],
  loaded: false,
};

export function magicMileReducer(state: MagicMileState = initialState, action: MagicMileAction): MagicMileState {
  switch (action.type) {
    case MagicMileActionTypes.Loaded: {
      return {
        ...state,
        list: action.payload,
        loaded: true,
        error: null,
      };
    }
    case MagicMileActionTypes.LoadError: {
      return {
        ...state,
        error: action.payload,
      };
    }
  }
  return state;
}
