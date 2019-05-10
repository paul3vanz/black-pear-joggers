import { createSelector } from '@ngrx/store';
import { Standard } from '../models/standard';
import { StandardsActionsTypes, StandardsActions } from '../actions/standards';

export interface State {
  loading: boolean;
  standards: Standard[];
  selected: Event;
}

export const initialState: State = {
  loading: false,
  standards: null,
  selected: null,
};

export function reducer(state = initialState, action: StandardsActions): State {
  switch (action.type) {
    case StandardsActionsTypes.GET:
      return {
        ...state,
        loading: true,
      };
    case StandardsActionsTypes.GET_SUCCESS:
      return {
        ...state,
        loading: false,
        standards: action.payload,
      };
    case StandardsActionsTypes.GET_FAIL:
      return {
        ...state,
        loading: false,
      };
    default:
      return state;
  }
}

export const getState = (state: { [reducer: string]: any }) => state.standards;

export const getStandards = createSelector(getState, (state: State) => {
  if (!state.standards) {
    return null;
  }
  const output: Array<any> = [ { events: [] } ];
  let currentEvent: string = null;
  let currentAward: string = null;
  let currentEventIndex = -1;
  let currentAwardIndex = -1;
  state.standards.forEach((s) => {
    if (currentEvent !== s.event) {
      ++currentEventIndex;
      currentEvent = s.event;
      output[currentEventIndex] = { name: currentEvent, standards: [] };
      currentAwardIndex = -1;
    }
    if (currentAward !== s.name) {
      ++currentAwardIndex;
      currentAward = s.name;
      output[currentEventIndex].standards[currentAwardIndex] = { name: s.name, time: s.time, timeParsed: s.time_parsed };
    }
  });
  return output;
});
