import { createAction, props } from '@ngrx/store';
import { ClubRecord } from '../models/club-record.model';
import { ClubRecordQuery } from '../models/club-record-query.model';

export const load = createAction('[Club Records] Load');

export const loaded = createAction(
  '[Club Records] Loaded',
  props<{
    records: ClubRecord[];
  }>()
);

export const loadError = createAction(
  '[Club Records] Load Error',
  props<{
    error: string;
  }>()
);

export const select = createAction(
  '[Club Records] Select',
  props<{ record: ClubRecord }>()
);

export const sendQuery = createAction(
  '[Club Records] Send Query',
  props<{
    clubRecordQuery: ClubRecordQuery;
  }>()
);

export const sendQuerySuccess = createAction(
  '[Club Records] Send Query Success'
);

export const sendQueryError = createAction('[Club Records] Send Query Error');

export const clubRecordsActions = {
  load,
  loaded,
  loadError,
  select,
  sendQuery,
  sendQuerySuccess,
  sendQueryError
};
