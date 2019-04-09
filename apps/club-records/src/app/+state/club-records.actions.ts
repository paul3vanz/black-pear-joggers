import { Action } from '@ngrx/store';
import { ClubRecord } from '../models/club-record.model';

export enum ClubRecordsActionTypes {
  Load = '[Club Records] Load',
  Loaded = '[Club Records] Loaded',
  LoadError = '[Club Records] Load Error',
  Select = '[Club Records] Select',
  SendQuery = '[Club Records] Send Query',
  SendQuerySuccess = '[Club Records] Send Query Success',
  SendQueryError = '[Club Records] Send Query Error',
}

export class Load implements Action {
  readonly type = ClubRecordsActionTypes.Load;
}

export class LoadError implements Action {
  readonly type = ClubRecordsActionTypes.LoadError;
  constructor(public payload: any) {}
}

export class Loaded implements Action {
  readonly type = ClubRecordsActionTypes.Loaded;
  constructor(public payload: ClubRecord[]) {}
}

export class Select implements Action {
  readonly type = ClubRecordsActionTypes.Select;
  constructor(public payload: ClubRecord) {}
}

export class SendQuery implements Action {
  readonly type = ClubRecordsActionTypes.SendQuery;
  constructor(public record: ClubRecord, public reason: string) {}
}

export class SendQuerySuccess implements Action {
  readonly type = ClubRecordsActionTypes.SendQuerySuccess;
  constructor(public payload: any) {}
}

export class SendQueryError implements Action {
  readonly type = ClubRecordsActionTypes.SendQueryError;
  constructor(public payload: any) {}
}

export type ClubRecordsAction = Load | Loaded | LoadError | Select | SendQuery | SendQuerySuccess | SendQueryError;

export const fromClubRecordsActions = {
  Load,
  Loaded,
  LoadError,
  Select,
  SendQuery,
  SendQuerySuccess,
  SendQueryError,
};
