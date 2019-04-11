import { Injectable } from '@angular/core';
import { Effect, Actions } from '@ngrx/effects';

import { Search, SearchActionTypes } from './search.actions';

@Injectable()
export class SearchEffects {
  constructor(private actions$: Actions) {}
}
