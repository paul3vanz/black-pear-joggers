import { createAction, props } from '@ngrx/store';
import { Paging } from '../models/paging.model';
import { Result } from '../models/result.model';

export namespace resultsActions {
  export const load = createAction('[Results] Load', props<{ athleteId?: number; page?: number }>());

  export const loadSuccess = createAction('[Results] Load Success', props<{ results: Paging<Result> }>());

  export const loadFailure = createAction('[Results] Load Failure', props<{ error: string }>());

  export const select = createAction('[Results] Select', props<{ athleteId: number }>());
}
