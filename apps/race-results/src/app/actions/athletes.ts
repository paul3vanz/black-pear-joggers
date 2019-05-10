import { Action } from '@ngrx/store';
import { Athlete } from '../models/athlete';
import { Paging } from '../models/paging';

export enum AthletesActionTypes {
  GET = '[Athletes] Load',
  GET_SUCCESS = '[Athletes] Load Success',
  GET_FAIL = '[Athletes] Load Fail',
  SEARCH = '[Athletes] Search',
  SEARCH_SUCCESS = '[Athletes] Search Success',
  SEARCH_FAIL = '[Athletes] Search Fail',
  SELECT = '[Athlete] Select',
}

export class GetAction implements Action {
  readonly type = AthletesActionTypes.GET;
  payload: string;

  constructor(athleteId?: string) {
    this.payload = athleteId;
  }
}

export class GetSuccessAction implements Action {
  readonly type = AthletesActionTypes.GET_SUCCESS;
  payload: Athlete;

  constructor(athletes: Athlete) {
    this.payload = athletes;
  }
}

export class GetFailAction implements Action {
  readonly type = AthletesActionTypes.GET_FAIL;
}

export class SearchAction implements Action {
  readonly type = AthletesActionTypes.SEARCH;
  payload: string;

  constructor(keywords: string) {
    this.payload = keywords;
  }
}

export class SearchSuccessAction implements Action {
  readonly type = AthletesActionTypes.SEARCH_SUCCESS;
  payload: Paging<Athlete>;

  constructor(athletes: Paging<Athlete>) {
    this.payload = athletes;
  }
}

export class SearchFailAction implements Action {
  readonly type = AthletesActionTypes.SEARCH_FAIL;
}

export class SelectAction implements Action {
  readonly type = AthletesActionTypes.SELECT;
  payload: number;

  constructor(athleteId: number) {
    this.payload = athleteId;
  }
}

export type AthletesActions =
  | GetAction
  | GetSuccessAction
  | GetFailAction
  | SearchAction
  | SearchSuccessAction
  | SearchFailAction
  | SelectAction;
