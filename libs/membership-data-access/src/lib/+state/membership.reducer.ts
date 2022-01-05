import { LoadingState, LoadingStates } from 'libs/race-results-data-access/src/lib/models/loading-state.model';
import { createReducer, on } from '@ngrx/store';

import { Membership } from '../models/membership.model';
import { membershipActions } from './membership.actions';

export const FEATURE_KEY = 'membership';

export interface State {
  list: Membership[];
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

const _reducer = createReducer(
  initialState,
  on(membershipActions.loadMembership, (state) => {
    return {
      ...state,
      callState: LoadingStates.LOADING,
    };
  }),
  on(membershipActions.loadMembershipSuccess, (state, action) => {
    return {
      ...state,
      list: action.memberships,
      callState: LoadingStates.LOADED,
    };
  }),
  on(membershipActions.loadMembershipError, (state, action) => {
    return {
      ...state,
      list: [],
      callState: { error: action.error },
    };
  })
);

export function reducer(state, action) {
  return _reducer(state, action);
}
