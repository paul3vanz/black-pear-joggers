import { createAction, props } from '@ngrx/store';

export namespace authActions {
  export const check = createAction('[Auth] Check');

  export const checkIsAuthenticated = createAction('[Auth] Check Is Authenticated', props<{ user: any }>());

  export const checkIsUnauthenticated = createAction('[Auth] Check Is Unauthenticated');

  export const checkError = createAction('[Auth] Check Error', props<{ error: any }>());

  export const signIn = createAction(
    '[Auth] Sign In',
    props<{
      username: string;
      password: string;
    }>()
  );

  export const signInSuccess = createAction('[Auth] Sign In Success');

  export const signInFailure = createAction('[Auth] Sign In Failure');

  export const signOut = createAction('[Auth] Sign Out');
}
