import { createSelector } from '@ngrx/store';
import { Athlete } from '../models/athlete';
import { AthletesActionTypes, AthletesActions } from '../actions/athletes';
import { Paging } from '../models/paging';

export interface State {
  loading: boolean;
  athletes: Paging<Athlete>;
  selected: Athlete;
  search: string;
}

export const initialState: State = {
  loading: false,
  athletes: null,
  selected: null,
  search: null,
};

export function reducer(state = initialState, action: AthletesActions): State {
  // console.log(action);
  switch (action.type) {
    case AthletesActionTypes.GET:
      return {
        ...state,
        loading: true,
      };
    case AthletesActionTypes.GET_SUCCESS:
      return {
        ...state,
        loading: false,
        selected: action.payload,
      };
    case AthletesActionTypes.GET_FAIL:
      return {
        ...state,
        loading: false,
      };
    case AthletesActionTypes.SEARCH:
      return {
        ...state,
        loading: true,
        search: action.payload,
      };
    case AthletesActionTypes.SEARCH_SUCCESS:
      return {
        ...state,
        loading: false,
        athletes: action.payload,
      };
    case AthletesActionTypes.SEARCH_FAIL:
      return {
        ...state,
        loading: false,
      };
    case AthletesActionTypes.SELECT:
      return {
        ...state,
        selected: state.athletes ? state.athletes.data[action.payload] : null,
      };
    default:
      return state;
  }
}

export const getState = (state: { [reducer: string]: any }) => state.athletes;

export const getLoading = createSelector(getState, (state: State) => state.loading);
