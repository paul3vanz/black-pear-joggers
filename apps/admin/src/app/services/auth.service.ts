import { Injectable } from '@angular/core';
import { of } from 'rxjs';
import {AuthenticationDetails, CognitoUser, CognitoUserAttribute, CognitoUserPool, ICognitoUserPoolData} from 'amazon-cognito-identity-js';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  // https://blackpearjoggers.auth.us-east-1.amazoncognito.com/login?response_type=token&client_id=340gm7r5u38dpb0t5ipc2eamrt&redirect_uri=http://localhost:4200/?action=signed-in

  cognitoUserPoolData: ICognitoUserPoolData = {
    UserPoolId: 'us-east-1_ZrnykIqVi',
    ClientId: '340gm7r5u38dpb0t5ipc2eamrt',
  };

  cognitoUserPool = new CognitoUserPool(this.cognitoUserPoolData);

  signIn(username: string, password: string) {
    const authDetails = new AuthenticationDetails({
      Username: username,
      Password: password
    });
    const userData = {
      Username: username,
      Pool: this.cognitoUserPool
    };
    const cognitoUser = new CognitoUser(userData);

    cognitoUser.authenticateUser(authDetails, {
      onSuccess: (result) => {
        console.log('You are now Logged in');
      },
      onFailure: (err) => {
        console.log('There was an error during login, please try again -> ', err)
      }
    })
  }

  check() {
    console.log('auth service - check');

    this.signIn('paul@3vanz.co.uk', 'Password1!');

    return of({
      username: 'paul3vanz'
    });
  }

  constructor() {}
}
