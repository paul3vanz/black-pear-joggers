import { Action, createReducer, on } from '@ngrx/store';

import { authActions } from '../actions/auth.actions';
import { LoadingState, LoadingStates } from '../../models/loading-state.model';

export namespace authReducer {
  export const AUTH_FEATURE_KEY = 'auth';

  export interface State {
    user: any;
    loadingState: LoadingState;
  }

  export interface AuthPartialState {
    readonly [AUTH_FEATURE_KEY]: State;
  }

  export const initialState: State = {
    user: null,
    loadingState: LoadingStates.INIT,
  };

  const authReducer = createReducer(
    initialState,
    on(authActions.check, (state) => ({
      ...state,
      loadingState: LoadingStates.LOADING,
    })),
    on(authActions.checkIsAuthenticated, (state, action) => ({
      ...state,
      user: action.user,
      loadingState: LoadingStates.LOADED,
    })),
    on(authActions.checkIsUnauthenticated, (state) => ({
      ...state,
      user: null,
      loadingState: LoadingStates.LOADED,
    })),
    on(authActions.checkError, (state) => ({
      ...state,
      user: null,
      loadingState: LoadingStates.LOADED,
    }))
  );

  export function reducer(state: State | undefined, action: Action) {
    return authReducer(state, action);
  }
}
