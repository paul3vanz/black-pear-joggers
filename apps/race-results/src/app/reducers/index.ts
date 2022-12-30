import * as meetingsReducer from './meetings';
import * as standardsReducer from './standards';
import { ActionReducerMap } from '@ngrx/store';

import { resultsReducer } from 'libs/race-results-data-access/src/lib/+state/results.reducer';


export interface State {
    meetings: meetingsReducer.State;
    results: resultsReducer.State;
    standards: standardsReducer.State;
}

export const reducers: ActionReducerMap<State> = {
    meetings: meetingsReducer.reducer,
    results: resultsReducer.reducer,
    standards: standardsReducer.reducer,
};
