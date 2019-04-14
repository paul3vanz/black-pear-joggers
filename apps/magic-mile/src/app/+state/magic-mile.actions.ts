import { Action } from '@ngrx/store';
import { Entity } from './magic-mile.reducer';

export enum MagicMileActionTypes {
  Load = '[Magic Mile] Load',
  Loaded = '[Magic Mile] Loaded',
  LoadError = '[Magic Mile] Load Error',
  Search = '[Magic Mile] Search',
  SetYear = '[Magic Mile] Set Year'
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
  constructor(public payload: Entity[]) {}
}

export class Search implements Action {
  readonly type = MagicMileActionTypes.Search;
  constructor(public payload: string) {}
}

export class SetYear implements Action {
  readonly type = MagicMileActionTypes.SetYear;
  constructor(public payload: string) {}
}

export type MagicMileAction = Load | Loaded | LoadError | Search | SetYear;

export const fromMagicMileActions = {
  Load,
  Loaded,
  LoadError,
  Search,
  SetYear
};
