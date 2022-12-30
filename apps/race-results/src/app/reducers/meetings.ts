import * as meetingsActions from '../actions/meetings';
import { createSelector } from '@ngrx/store';
import { Meeting } from '../models/meeting';
import { Paging } from '../models/paging';


export interface State {
    meetings: Paging<Meeting>;
    loading: boolean;
    search: string;
    selected: Meeting;
}

export const initialState: State = {
    meetings: null,
    loading: false,
    search: null,
    selected: null,
};

export function reducer(state = initialState, action: meetingsActions.MeetingsActions): State {
    switch (action.type) {
        case meetingsActions.GET:
            return { ...state, loading: true };
        case meetingsActions.GET_SUCCESS:
            return { ...state, loading: false, meetings: action.payload };
        case meetingsActions.GET_FAIL:
            return { ...state, loading: false };
        case meetingsActions.SEARCH:
            return { ...state, loading: true, search: action.payload };
        case meetingsActions.SEARCH_SUCCESS:
            return { ...state, loading: false, meetings: action.payload };
        case meetingsActions.SEARCH_FAIL:
            return { ...state, loading: false };
        default:
            return state;
    }
}

export const getState = (state: { [reducer: string]: any }) => state.meetings;

export const getLoading = createSelector(getState, (state: State) => state.loading);
