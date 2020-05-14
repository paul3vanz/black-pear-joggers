import { Actions, createEffect, ofType } from '@ngrx/effects';
import { Injectable } from '@angular/core';
import { of } from 'rxjs';
import { switchMap, map, catchError } from 'rxjs/operators';

import { authActions } from '../actions/auth.actions';
import { AuthService } from '../../services/auth.service';
import { Router } from '@angular/router';

@Injectable()
export class AuthEffects {
  check$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.check),
      switchMap(() => {
        return this.authService.check().pipe(
          map((user) => authActions.checkIsAuthenticated({ user })),
          catchError((error) => of(authActions.checkError({ error })))
        );
      })
    )
  );

  checkIsAuthenticated$ = createEffect(
    () =>
      this.actions$.pipe(
        ofType(authActions.checkIsAuthenticated),
        map(() => this.router.navigate(['/athletes']))
      ),
    { dispatch: false }
  );

  signOut$ = createEffect(
    () =>
      this.actions$.pipe(
        ofType(authActions.signOut),
        map(() => this.authService.signOut())
      ),
    { dispatch: false }
  );

  constructor(private actions$: Actions, private authService: AuthService, private router: Router) {}
}
