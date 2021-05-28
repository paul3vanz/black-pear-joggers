import * as membershipReducer from './membership.reducer';

import { createFeatureSelector, createSelector } from '@ngrx/store';

export namespace membershipSelectors {
  export const getMembershipState = createFeatureSelector<membershipReducer.State>(membershipReducer.FEATURE_KEY);

  export const getCallState = createSelector(getMembershipState, (state: membershipReducer.State) => state.callState);

  export const getError = createSelector(getMembershipState, (state: membershipReducer.State) => state.callState);

  export const getAllMembership = createSelector(getMembershipState, getCallState, (state: membershipReducer.State) => state.list);
}
