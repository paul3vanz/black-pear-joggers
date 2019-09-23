import * as magicMileActions from './magic-mile.actions';
import { MagicMile } from '../models/magic-mile.model';
import { createReducer, on } from '@ngrx/store';
import { LoadingState, LoadingStates } from 'libs/authentication/src/lib/models/loading-state.model';

export const FEATURE_KEY = 'magicMile';

export interface State {
  list: MagicMile[];
  selectedId?: number;
  callState: LoadingState;
}

export interface PartialState {
  readonly [FEATURE_KEY]: State;
}

export const initialState: State = {
  list: [],
  callState: LoadingStates.INIT,
};

const _reducer = createReducer(initialState,
  on(magicMileActions.loadResults, (state, action) => {
    return {
      ...state,
      callState: LoadingStates.LOADING,
    };
  }),

  on(magicMileActions.loadResultsSuccess, (state, action) => {
    return {
      ...state,
      list: action.results,
      callState: LoadingStates.LOADED,
    };
  }),
  on(magicMileActions.loadResultsError, (state, action) => {
    return {
      ...state,
      list: [],
      callState: { error: action.error },
    };
  }),
  on(magicMileActions.deleteResultSuccess, (state, action) => {
    return {
      ...state,
      list: state.list.filter((result) => result.id !== Number(action.resultId)),
    };
  })
);

export function reducer(state, action) {
  return _reducer(state, action);
}
