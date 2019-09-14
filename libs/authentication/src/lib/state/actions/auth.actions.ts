import { createAction, props } from '@ngrx/store';

export const check = createAction(
  '[Auth] Check'
);

export const checkIsAuthenticated = createAction(
  '[Auth] Is Authenticated',
  props<{ user: any }>()
);

export const checkIsUnauthenticated = createAction(
  '[Auth] Is Unauthenticated'
);

export const checkError = createAction(
  '[Auth] Check Error',
  props<{ error: any }>()
);
