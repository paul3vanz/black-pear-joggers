import { Action, createReducer, on } from '@ngrx/store';
import { LoadingState, LoadingStates } from '../models/loading-state.model';
import { Paging } from '../models/paging.model';
import { Result } from '../models/result.model';

import { resultsActions } from '../+state/results.actions';

export namespace resultsReducer {
    export interface State {
        loadingState: LoadingState;
        records: Paging<Result>;
    }

    export const initialState: State = {
        loadingState: LoadingStates.INIT,
        records: undefined,
    };

    const resultsReducer = createReducer(
        initialState,
        on(resultsActions.load, (state) => ({
            ...state,
            records: null,
            loadingState: LoadingStates.LOADING,
        })),
        on(resultsActions.loadSuccess, (state, { results }) => ({
            ...state,
            records: results,
            loadingState: LoadingStates.LOADED,
        })),
        on(resultsActions.loadFailure, (state, { error }) => ({
            ...state,
            loadingState: { error },
        }))
    );

    export function reducer(state: State | undefined, action: Action) {
        return resultsReducer(state, action);
    }
}
