import { ActionReducerMap } from '@ngrx/store';

import * as eventsReducer from './events';
import * as resultsReducer from './results';
import * as standardsReducer from './standards';

export interface State {
  events: eventsReducer.State;
  results: resultsReducer.State;
  standards: standardsReducer.State;
}

export const reducers: ActionReducerMap<State> = {
  events: eventsReducer.reducer,
  results: resultsReducer.reducer,
  standards: standardsReducer.reducer
};
