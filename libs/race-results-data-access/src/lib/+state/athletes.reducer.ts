import { Athlete } from '../models/athlete.model';
import { createReducer, on, Action } from '@ngrx/store';
import * as athletesActions from './athletes.actions';
import { LoadingState, LoadingStates } from '../models/loading-state.model';

export const ATHLETES_FEATURE_KEY = 'athletes';

export interface AthletesState {
  loadingState: LoadingState;
  records: Athlete[];
  selected?: number;
  search: string;
}

export interface AthletesPartialState {
  readonly [ATHLETES_FEATURE_KEY]: AthletesState;
}

export const initialState: AthletesState = {
  records: [],
  loadingState: LoadingStates.INIT,
  search: null
};

const athletesReducer = createReducer(
  initialState,
  on(athletesActions.load, state => ({
    ...state,
    records: [],
    loadingState: LoadingStates.LOADING
  })),
  on(athletesActions.loadSuccess, (state, { athletes }) => ({
    ...state,
    records: athletes,
    loadingState: LoadingStates.LOADED
  })),
  on(athletesActions.loadFailure, (state, { error }) => ({
    ...state,
    loadingState: {
      error: error
    }
  })),
  on(athletesActions.search, (state, { keywords }) => ({
    ...state,
    search: keywords
  })),
  on(athletesActions.select, (state, { athleteId }) => ({
    ...state,
    selected: athleteId
  }))
);

export function reducer(state: AthletesState | undefined, action: Action) {
  return athletesReducer(state, action);
}
