import { Component, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import { AuthState } from './state/reducers/auth.reducer';

import * as AuthActions from './state/actions/auth.actions';

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
