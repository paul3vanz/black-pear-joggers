import { ActionReducerMap } from '@ngrx/store';

import { resultsReducer } from 'libs/race-results-data-access/src/lib/+state/results.reducer';

import * as eventsReducer from './events';
import * as standardsReducer from './standards';

export interface State {
  events: eventsReducer.State;
  results: resultsReducer.State;
  standards: standardsReducer.State;
}

export const reducers: ActionReducerMap<State> = {
  events: eventsReducer.reducer,
  results: resultsReducer.reducer,
  standards: standardsReducer.reducer,
};
