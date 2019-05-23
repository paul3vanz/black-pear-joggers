import { Action } from '@ngrx/store';
import { Ranking } from '../models/ranking';

export enum RankingsActionsTypes {
  GET = '[Rankings] Load',
  GET_SUCCESS = '[Rankings] Load Success',
  GET_FAIL = '[Rankings] Load Fail',
}

export class GetAction implements Action {
  readonly type = RankingsActionsTypes.GET;
  payload: number;

  constructor(athleteId?: number) {
    this.payload = athleteId;
  }
}

export class GetSuccessAction implements Action {
  readonly type = RankingsActionsTypes.GET_SUCCESS;

  constructor(public payload: Ranking[]) {}
}

export class GetFailAction implements Action {
  readonly type = RankingsActionsTypes.GET_FAIL;
}

export type RankingsActions = GetAction | GetSuccessAction | GetFailAction;
