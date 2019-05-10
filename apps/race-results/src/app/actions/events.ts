import { Action } from '@ngrx/store';
import { Event } from '../models/event';
import { Paging } from '../models/paging';

export const GET = '[Events] Load';
export const GET_SUCCESS = '[Events] Load Success';
export const GET_FAIL = '[Events] Load Fail';
export const SEARCH = '[Events] Search';
export const SEARCH_SUCCESS = '[Events] Search Success';
export const SEARCH_FAIL = '[Events] Search Fail';

export class GetAction implements Action {
  readonly type = GET;
}

export class GetSuccessAction implements Action {
  readonly type = GET_SUCCESS;

  constructor(public payload: Paging<Event>) {}
}

export class GetFailAction implements Action {
  readonly type = GET_FAIL;
}

export class SearchAction implements Action {
  readonly type = SEARCH;
  payload: string;

  constructor(keywords: string) {
    this.payload = keywords;
  }
}

export class SearchSuccessAction implements Action {
  readonly type = SEARCH_SUCCESS;
  payload: Paging<Event>;

  constructor(athletes: Paging<Event>) {
    this.payload = athletes;
  }
}

export class SearchFailAction implements Action {
  readonly type = SEARCH_FAIL;
}

export type EventsActions = GetAction | GetSuccessAction | GetFailAction | SearchAction | SearchSuccessAction | SearchFailAction;
