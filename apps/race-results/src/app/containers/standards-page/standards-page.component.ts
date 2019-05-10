import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import * as rootReducer from '../../reducers';
import * as standardsReducer from '../../reducers/standards';
import { Standard } from '../../models/standard';
import { Store } from '@ngrx/store';

@Component({
  selector: 'bpj-standards-page',
  templateUrl: './standards-page.component.html',
  styleUrls: [ './standards-page.component.css' ],
})
export class StandardsPageComponent implements OnInit {
  standards$: Observable<Standard[]>;
  standardsLoading$: Observable<boolean>;

  constructor(private store$: Store<rootReducer.State>) {
    this.standardsLoading$ = this.store$.select((store) => store.standards.loading);
    this.standards$ = this.store$.select(standardsReducer.getStandards);
  }

  ngOnInit() {}
}
