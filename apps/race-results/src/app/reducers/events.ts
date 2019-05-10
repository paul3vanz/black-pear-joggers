import { createSelector } from '@ngrx/store';

import { Paging } from '../models/paging';
import { Event } from '../models/event';
import * as eventsActions from '../actions/events';

export interface State {
  events: Paging<Event>;
  loading: boolean;
  search: string;
  selected: Event;
}

export const initialState: State = {
  events: null,
  loading: false,
  search: null,
  selected: null,
};

export function reducer(state = initialState, action: eventsActions.EventsActions): State {
  switch (action.type) {
    case eventsActions.GET:
      return { ...state, loading: true };
    case eventsActions.GET_SUCCESS:
      return { ...state, loading: false, events: action.payload };
    case eventsActions.GET_FAIL:
      return { ...state, loading: false };
    case eventsActions.SEARCH:
      return { ...state, loading: true, search: action.payload };
    case eventsActions.SEARCH_SUCCESS:
      return { ...state, loading: false, events: action.payload };
    case eventsActions.SEARCH_FAIL:
      return { ...state, loading: false };
    default:
      return state;
  }
}

export const getState = (state: { [reducer: string]: any }) => state.events;

export const getLoading = createSelector(getState, (state: State) => state.loading);
