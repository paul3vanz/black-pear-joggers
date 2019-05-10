import { Action } from '@ngrx/store';
import { MagicMile } from '../models/magic-mile.model';

export enum MagicMileActionTypes {
  Load = '[Magic Mile] Load',
  Loaded = '[Magic Mile] Loaded',
  LoadError = '[Magic Mile] Load Error',
}

export class Load implements Action {
  readonly type = MagicMileActionTypes.Load;
}

export class LoadError implements Action {
  readonly type = MagicMileActionTypes.LoadError;
  constructor(public payload: any) {}
}

export class Loaded implements Action {
  readonly type = MagicMileActionTypes.Loaded;
  constructor(public payload: MagicMile[]) {}
}

export type MagicMileAction = Load | Loaded | LoadError;

export const fromMagicMileActions = {
  Load,
  Loaded,
  LoadError,
};
