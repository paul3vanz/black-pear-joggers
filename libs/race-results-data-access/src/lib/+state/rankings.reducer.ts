import { Ranking } from '../models/ranking.model';
import { createReducer, on, Action } from '@ngrx/store';
import * as rankingsActions from './rankings.actions';

export const FEATURE_KEY = 'rankings';

export interface State {
  rankings: Ranking[];
  loading: boolean;
  error: boolean;
}

export const initialState: State = {
  rankings: [],
  loading: false,
  error: false
};

const rankingsReducer = createReducer(
  initialState,
  on(rankingsActions.loadAction, state => ({
    ...state,
    rankings: [],
    loading: true,
    error: false
  })),
  on(rankingsActions.loadSuccessAction, (state, { rankings }) => ({
    ...state,
    rankings: rankings,
    loading: false,
    error: false
  })),
  on(rankingsActions.loadFailureAction, state => ({
    ...state,
    loading: false,
    error: true
  }))
);

export function reducer(state: State | undefined, action: Action) {
  return rankingsReducer(state, action);
}
