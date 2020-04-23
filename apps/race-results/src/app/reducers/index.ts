import { ActionReducerMap } from '@ngrx/store';
import * as athletesReducer from './athletes';
import * as eventsReducer from './events';
import * as resultsReducer from './results';
import * as standardsReducer from './standards';

export interface State {
  athletes: athletesReducer.State;
  events: eventsReducer.State;
  rankings: any;
  results: resultsReducer.State;
  standards: standardsReducer.State;
}

export const reducers: ActionReducerMap<State> = {
  athletes: athletesReducer.reducer,
  events: eventsReducer.reducer,
  rankings: null,
  results: resultsReducer.reducer,
  standards: standardsReducer.reducer
};
