import { ClubRecordsAction, ClubRecordsActionTypes } from './club-records.actions';
import { ClubRecord } from '../models/club-record.model';

export const CLUBRECORDS_FEATURE_KEY = 'clubRecords';

export interface ClubRecordsState {
  list: ClubRecord[];
  selected?: ClubRecord;
  loaded: boolean;
  error?: any;
}

export interface ClubRecordsPartialState {
  readonly [CLUBRECORDS_FEATURE_KEY]: ClubRecordsState;
}

export const initialState: ClubRecordsState = {
  list: [],
  loaded: false,
};

export function clubRecordsReducer(state: ClubRecordsState = initialState, action: ClubRecordsAction): ClubRecordsState {
  switch (action.type) {
    case ClubRecordsActionTypes.Loaded: {
      state = {
        ...state,
        list: action.payload,
        loaded: true,
      };
      break;
    }
    case ClubRecordsActionTypes.Select: {
      state = {
        ...state,
        selected: action.payload,
      };
      break;
    }
  }
  return state;
}
