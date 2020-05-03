import { createAction, props } from '@ngrx/store';

import { Ranking } from '../models/ranking.model';

export const load = createAction(
  '[Rankings] Load',
  props<{ athleteId: number }>()
);

export const loadSuccess = createAction(
  '[Rankings] Load Success',
  props<{ rankings: Ranking[] }>()
);

export const loadFailure = createAction(
  '[Rankings] Load Failure',
  props<{ error: string }>()
);

export const rankingsActions = {
  load,
  loadSuccess,
  loadFailure
};
