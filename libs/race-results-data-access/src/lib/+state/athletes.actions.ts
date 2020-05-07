import { createAction, props } from '@ngrx/store';
import { Athlete } from '../models/athlete.model';

export namespace athletesActions {
  export const load = createAction(
    '[Athletes] Load',
    props<{ athleteId?: number }>()
  );

  export const loadSuccess = createAction(
    '[Athletes] Load Success',
    props<{ athletes: Athlete[] }>()
  );

  export const loadFailure = createAction(
    '[Athletes] Load Failure',
    props<{ error: string }>()
  );

  export const search = createAction(
    '[Athletes] Search',
    props<{ keywords: string }>()
  );

  export const searchSuccess = createAction(
    '[Athletes] Search Success',
    props<{ athletes: Athlete[] }>()
  );

  export const searchFailure = createAction('[Athletes] Search Fail');

  export const select = createAction(
    '[Athlete] Select',
    props<{ athleteId: number }>()
  );
}
