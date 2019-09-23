import { createAction, props } from '@ngrx/store';
import { MagicMile } from '../models/magic-mile.model';

export const loadResults = createAction(
  '[Magic Mile] Load'
);

export const loadResultsError = createAction(
  '[Magic Mile] Load Error',
  props<{ error: any }>()
);

export const loadResultsSuccess = createAction(
  '[Magic Mile] Load Success',
  props<{ results: MagicMile[] }>()
);

export const createResult = createAction(
  '[Magic Mile] Create'
);

export const createResultError = createAction(
  '[Magic Mile] Create Error',
  props<{ error: any }>()
);

export const createResultSuccess = createAction(
  '[Magic Mile] Create Success',
  props<{ result: MagicMile }>()
);

export const deleteResult = createAction(
  '[Magic Mile] Delete',
  props<{ result: MagicMile }>()
);

export const deleteResultError = createAction(
  '[Magic Mile] Delete Error',
  props<{ error: any }>()
);

export const deleteResultSuccess = createAction(
  '[Magic Mile] Delete Success',
  props<{ resultId: string }>()
);