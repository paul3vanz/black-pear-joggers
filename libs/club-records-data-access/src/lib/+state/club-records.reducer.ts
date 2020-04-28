import { clubRecordsActions } from './club-records.actions';
import { ClubRecord } from '../models/club-record.model';
import { createReducer, on, Action } from '@ngrx/store';

export const CLUB_RECORDS_FEATURE_KEY = 'clubRecords';

export interface ClubRecordsState {
  records: ClubRecord[];
  selected?: ClubRecord;
  loaded: boolean;
  error?: any;
}

export interface ClubRecordsPartialState {
  readonly [CLUB_RECORDS_FEATURE_KEY]: ClubRecordsState;
}

export const initialState: ClubRecordsState = {
  records: [],
  loaded: false
};

const clubRecordsReducer = createReducer(
  initialState,
  on(clubRecordsActions.loaded, (state, action) => {
    return {
      ...state,
      records: action.records,
      loaded: true
    };
  }),
  on(clubRecordsActions.select, (state, action) => {
    return {
      ...state,
      selected: action.record
    };
  })
);

export function reducer(state: ClubRecordsState | undefined, action: Action) {
  return clubRecordsReducer(state, action);
}
