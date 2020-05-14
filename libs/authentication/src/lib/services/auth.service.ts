import { Auth } from 'aws-amplify';
import { Injectable } from '@angular/core';
import { from, throwError } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  signIn(username: string, password: string) {
    return from(Auth.signIn(username, password)).pipe(catchError((error) => throwError(error)));
  }

  signOut() {
    return from(Auth.signOut()).pipe(catchError((error) => throwError(error)));
  }

  check() {
    return from(Auth.currentUserInfo()).pipe(
      map(({ attributes }) => {
        return {
          email: attributes.email,
          emailVerified: attributes.email_verified,
          phoneNumber: attributes.phone_number,
          phoneNumberVerified: attributes.phone_number_verified,
          username: attributes.sub,
        };
      }),
      catchError((error) => throwError(error))
    );
  }

  constructor() {}
}
