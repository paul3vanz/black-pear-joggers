import { Ranking } from '../models/ranking.model';
import { createReducer, on, Action } from '@ngrx/store';
import { rankingsActions } from './rankings.actions';
import { LoadingState, LoadingStates } from '../models/loading-state.model';

export namespace rankingsReducer {
  export const FEATURE_KEY = 'rankings';

  export interface State {
    records: Ranking[];
    loadingState: LoadingState;
  }

  export const initialState: State = {
    records: [],
    loadingState: LoadingStates.INIT
  };

  const rankingsReducer = createReducer(
    initialState,
    on(rankingsActions.load, state => ({
      ...state,
      records: [],
      loadingState: LoadingStates.LOADING
    })),
    on(rankingsActions.loadSuccess, (state, { rankings }) => ({
      ...state,
      records: rankings,
      loadingState: LoadingStates.LOADED
    })),
    on(rankingsActions.loadFailure, (state, { error }) => ({
      ...state,
      loadingState: { error }
    }))
  );

  export function reducer(state: State | undefined, action: Action) {
    return rankingsReducer(state, action);
  }
}
