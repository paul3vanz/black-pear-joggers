import * as magicMileActions from './magic-mile.actions';
import { MagicMile } from '../models/magic-mile.model';
import { createReducer, on } from '@ngrx/store';
import { LoadingState, LoadingStates } from 'libs/race-results-data-access/src/lib/models/loading-state.model';

export const FEATURE_KEY = 'magicMile';

export interface State {
  list: MagicMile[];
  athletes: any[];
  selectedId?: number;
  callState: LoadingState;
}

export interface PartialState {
  readonly [FEATURE_KEY]: State;
}

export const initialState: State = {
  list: [],
  athletes: [],
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
  on(magicMileActions.searchAthletes, (state) => {
    return {
      ...state,
      callState: LoadingStates.LOADING,
    };
  }),

  on(magicMileActions.searchAthletesSuccess, (state, action) => {
    return {
      ...state,
      athletes: action.athletes,
      callState: LoadingStates.LOADED,
    };
  }),
  on(magicMileActions.searchAthletesError, (state, action) => {
    return {
      ...state,
      athletes: [],
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
