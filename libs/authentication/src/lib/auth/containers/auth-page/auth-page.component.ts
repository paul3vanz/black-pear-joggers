import { Component } from '@angular/core';
import { Store } from '@ngrx/store';

import { authActions, authReducer } from '@black-pear-joggers/authentication';
import { Actions, ofType } from '@ngrx/effects';
import { tap } from 'rxjs/operators';
import { Router } from '@angular/router';

@Component({
  selector: 'bpj-auth-page',
  templateUrl: './auth-page.component.html',
  styleUrls: ['./auth-page.component.scss'],
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
        type: 'password',
      },
      {
        label: 'Phone Number',
        key: 'phone_number',
        required: true,
        displayOrder: 3,
        type: 'string',
      },
    ],
  };

  constructor(private store$: Store<authReducer.State>, private actions$: Actions, private router: Router) {}
}
