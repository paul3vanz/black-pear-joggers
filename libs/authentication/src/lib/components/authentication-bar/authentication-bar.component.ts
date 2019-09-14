import { Component, OnInit, Output, EventEmitter, Input } from '@angular/core';
import { AmplifyService } from 'aws-amplify-angular';
import { CognitoUser } from '@aws-amplify/auth';
import { AuthState } from 'aws-amplify-angular/dist/src/providers';

@Component({
  selector: 'bpj-authentication-bar',
  templateUrl: './authentication-bar.component.html',
  styleUrls: ['./authentication-bar.component.scss']
})
export class AuthenticationBarComponent implements OnInit {
  authState: AuthState;
  @Output() signIn = new EventEmitter<any>();
  @Output() signOut = new EventEmitter<any>();

  constructor(private amplifyService: AmplifyService) {
    this.amplifyService.authStateChange$.subscribe((authState) => {
      this.authState = authState;
      console.log(authState);
    });
  }

  ngOnInit() {
  }

  onSignIn() {
    this.signIn.emit();
  }

  onSignOut() {
    this.amplifyService.auth().signOut();
    this.signOut.emit();
  }

}
