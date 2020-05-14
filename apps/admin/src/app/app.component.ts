import { Component, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';

import { authActions } from '@black-pear-joggers/authentication';
import { authReducer } from 'libs/authentication/src/lib/state/reducers/auth.reducer';

@Component({
  selector: 'bpj-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
  ngOnInit() {
    this.store$.dispatch(authActions.check());
  }

  constructor(private store$: Store<authReducer.State>) {}

  onSignOut() {
    this.store$.dispatch(authActions.signOut());
  }
}
