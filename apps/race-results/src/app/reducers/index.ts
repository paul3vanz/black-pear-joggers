import * as eventsReducer from './meetings';
import * as standardsReducer from './standards';
import { ActionReducerMap } from '@ngrx/store';

import { resultsReducer } from 'libs/race-results-data-access/src/lib/+state/results.reducer';


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
