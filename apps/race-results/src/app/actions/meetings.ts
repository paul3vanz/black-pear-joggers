import { Action } from '@ngrx/store';
import { Meeting } from '../models/meeting';
import { Paging } from '../models/paging';

export const GET = '[Meetings] Load';
export const GET_SUCCESS = '[Meetings] Load Success';
export const GET_FAIL = '[Meetings] Load Fail';
export const SEARCH = '[Meetings] Search';
export const SEARCH_SUCCESS = '[Meetings] Search Success';
export const SEARCH_FAIL = '[Meetings] Search Fail';

export class GetAction implements Action {
    readonly type = GET;
}

export class GetSuccessAction implements Action {
    readonly type = GET_SUCCESS;

    constructor(public payload: Paging<Meeting>) { }
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
    payload: Paging<Meeting>;

    constructor(athletes: Paging<Meeting>) {
        this.payload = athletes;
    }
}

export class SearchFailAction implements Action {
    readonly type = SEARCH_FAIL;
}

export type MeetingsActions = GetAction | GetSuccessAction | GetFailAction | SearchAction | SearchSuccessAction | SearchFailAction;
