import { Injectable } from "@angular/core";
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { AuthService } from '../../services/auth.service';
import * as AuthActions from '../actions/auth.actions';
import { switchMap, map, catchError } from 'rxjs/operators';
import { of } from 'rxjs';

@Injectable()
export class AuthEffects {

  check$ = createEffect(() => this.actions$.pipe(
    ofType(AuthActions.check),
    switchMap(() => this.authService.check().pipe(
      map(user => ({ type: AuthActions.checkIsAuthenticated.type, user: user })),
      catchError(user => of({ type: AuthActions.checkError.type }))
    ))
  ));

  constructor(
    private actions$: Actions,
    private authService: AuthService
  ) {}
}
