import { Action } from '@ngrx/store';
import { Result } from '../models/result';
import { Paging } from '../models/paging';

export enum ResultsActionsTypes {
  GET = '[Results] Load',
  GET_SUCCESS = '[Results] Load Success',
  GET_FAIL = '[Results] Load Fail',
}

export class GetAction implements Action {
  readonly type = ResultsActionsTypes.GET;
  payload: {
    athleteId: string;
    page?: number;
  };

  constructor(athleteId: string, page?: number) {
    this.payload = {
      athleteId,
      page,
    };
  }
}

export class GetSuccessAction implements Action {
  readonly type = ResultsActionsTypes.GET_SUCCESS;

  constructor(public payload: Paging<Result>) {}
}

export class GetFailAction implements Action {
  readonly type = ResultsActionsTypes.GET_FAIL;
}

export type ResultsActions = GetAction | GetSuccessAction | GetFailAction;
