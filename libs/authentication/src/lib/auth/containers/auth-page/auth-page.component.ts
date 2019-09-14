import { AmplifyService } from 'aws-amplify-angular';
import { Component } from '@angular/core';
import { Store } from '@ngrx/store';

import * as authActions from '../../../state/actions/auth.actions';
import * as fromAuth from '../../../state/reducers/auth.reducer';
import { Actions, ofType } from '@ngrx/effects';
import { tap } from 'rxjs/operators';
import { Router } from '@angular/router';

@Component({
  selector: 'bpj-auth-page',
  templateUrl: './auth-page.component.html',
  styleUrls: ['./auth-page.component.scss']
})
export class AuthPageComponent {
  signUpConfig = {
    header: 'Create account',
    hideAllDefaults: true,
    defaultCountryCode: '44',
    signUpFields: [
      {
        label: 'Email',
        key: 'email',
        required: true,
        displayOrder: 1,
        type: 'string',
      },
      {
        label: 'Password',
        key: 'password',
        required: true,
        displayOrder: 2,
        type: 'password'
      },
      {
        label: 'Phone Number',
        key: 'phone_number',
        required: true,
        displayOrder: 3,
        type: 'string'
      },
    ]
  };

  constructor(
    private amplifyService: AmplifyService,
    private store$: Store<fromAuth.AuthState>,
    private actions$: Actions,
    private router: Router
  ) {
    this.amplifyService.authStateChange$
      .subscribe((authState) => {
        if (!authState.user) {
          this.store$.dispatch(authActions.checkIsUnauthenticated());
        } else {
          const userAttributes = authState.user.attributes;

          this.store$.dispatch(authActions.checkIsAuthenticated({
            user: {
              email: userAttributes.email,
              emailVerified: userAttributes.email_verified,
              phoneNumber: userAttributes.phone_number,
              phoneNumberVerified: userAttributes.phone_number_verified,
            },
          }));
        }
      });

    this.actions$.pipe(
      ofType(authActions.checkIsAuthenticated),
      tap(() => {
        console.log('authenticated redirect');
        setTimeout(() => {
          this.router.navigate(['/club-standards']);
        }, 0);
      })
    ).subscribe();
  }
}
