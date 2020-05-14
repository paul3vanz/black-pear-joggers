import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { Store } from '@ngrx/store';

import { authReducer } from '../../state/reducers/auth.reducer';
import { Observable } from 'rxjs';

@Component({
  selector: 'bpj-authentication-bar',
  templateUrl: './authentication-bar.component.html',
  styleUrls: ['./authentication-bar.component.scss'],
})
export class AuthenticationBarComponent implements OnInit {
  user$: Observable<any>;
  @Output() signIn = new EventEmitter<any>();
  @Output() signOut = new EventEmitter<any>();

  constructor(private store$: Store<authReducer.AuthPartialState>) {}

  ngOnInit() {
    this.user$ = this.store$.select((state) => state.auth.user);
  }

  onSignIn() {
    this.signIn.emit();
  }

  onSignOut() {
    this.signOut.emit();
  }
}
