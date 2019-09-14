import { Action, createReducer, on } from '@ngrx/store';

import { LoadingState, LoadingStates } from '../../models/loading-state.model';

import * as AuthActions from '../actions/auth.actions';

export const AUTH_FEATURE_KEY = 'Auth';

export interface AuthState {
  user: any;
  loadingState: LoadingState;
}

export interface AuthPartialState {
  readonly [AUTH_FEATURE_KEY]: AuthState;
}

export const initialState: AuthState = {
  user: null,
  loadingState: LoadingStates.INIT,
};

const authReducer = createReducer(
  initialState,
  on(AuthActions.check, state => ({
    ...state,
    loadingState: LoadingStates.LOADING,
  })),
  on(AuthActions.checkIsAuthenticated, state => ({
    ...state,
    user: state.user,
    loadingState: LoadingStates.LOADED
  })),
  on(AuthActions.checkIsUnauthenticated, state => ({
    ...state,
    user: null,
    loadingState: LoadingStates.LOADED,
  })),
  on(AuthActions.checkError, state => ({
    ...state,
    user: null,
    loadingState: LoadingStates.LOADED,
  }))
);

export function reducer(state: AuthState | undefined, action: Action) {
  return authReducer(state, action)
};
