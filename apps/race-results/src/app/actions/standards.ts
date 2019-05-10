import { Action } from '@ngrx/store';
import { Standard } from '../models/standard';

export enum StandardsActionsTypes {
    GET = '[Standards] Load',
    GET_SUCCESS = '[Standards] Load Success',
    GET_FAIL = '[Standards] Load Fail',
}

export class GetAction implements Action {
    readonly type = StandardsActionsTypes.GET;
    payload: {
        gender: string,
        category: string,
    };

    constructor(gender: string, category: string) {
        this.payload = {
            gender,
            category,
        };
    }
}

export class GetSuccessAction implements Action {
    readonly type = StandardsActionsTypes.GET_SUCCESS;

    constructor(public payload: Standard[]) {}
}

export class GetFailAction implements Action {
    readonly type = StandardsActionsTypes.GET_FAIL;
}

export type StandardsActions =
    GetAction |
    GetSuccessAction |
    GetFailAction;
