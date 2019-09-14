import { Component, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import { AuthState } from 'libs/authentication/src/lib/state/reducers/auth.reducer';

import * as AuthActions from 'libs/authentication/src/lib/state/actions/auth.actions';

@Component({
  selector: 'bpj-root',
  templateUrl: './app.component.html',
  styleUrls: [ './app.component.scss' ],
})
export class AppComponent implements OnInit {

  ngOnInit() {
    this.store$.dispatch(AuthActions.check());
  }

  constructor(
    private store$: Store<AuthState>
  ) {}

}
