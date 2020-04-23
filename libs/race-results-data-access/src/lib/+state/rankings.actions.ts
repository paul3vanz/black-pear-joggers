import { createAction, props } from '@ngrx/store';
import { Ranking } from '../models/ranking.model';

export const loadAction = createAction(
  '[Rankings] Load',
  props<{ athleteId: number }>()
);

export const loadSuccessAction = createAction(
  '[Rankings] Load Success',
  props<{
    rankings: Ranking[];
  }>()
);

export const loadFailureAction = createAction('[Rankings] Load Failure');
