import { createAction, props } from '@ngrx/store';

import { Membership } from '../models/membership.model';

export const loadMembership = createAction('[Membership] Load');

export const loadMembershipError = createAction('[Membership] Load Error', props<{ error: any }>());

export const loadMembershipSuccess = createAction('[Membership] Load Success', props<{ memberships: Membership[] }>());

export const membershipActions = {
  loadMembership,
  loadMembershipError,
  loadMembershipSuccess,
};
