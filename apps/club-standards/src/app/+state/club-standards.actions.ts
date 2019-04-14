import { Action } from '@ngrx/store';
import { Standard } from '../models/standard.model';

export enum ClubStandardsActionTypes {
  LoadClubStandards = '[Club Standards] Load',
  ClubStandardsLoaded = '[Club Standards] Loaded',
  ClubStandardsLoadError = '[Club Standards] Load Error',
  ClubStandardsSetGender = '[Club Standards] Set Gender',
  ClubStandardsSetCategory = '[Club Standards] Set Category',
}

export class LoadClubStandards implements Action {
  readonly type = ClubStandardsActionTypes.LoadClubStandards;
  constructor(public gender: string, public category: string) {}
}

export class ClubStandardsLoadError implements Action {
  readonly type = ClubStandardsActionTypes.ClubStandardsLoadError;
  constructor(public payload: any) {}
}

export class ClubStandardsLoaded implements Action {
  readonly type = ClubStandardsActionTypes.ClubStandardsLoaded;
  constructor(public payload: Standard[]) {}
}

export class ClubStandardsSetGender implements Action {
  readonly type = ClubStandardsActionTypes.ClubStandardsSetGender;
  constructor(public gender: string) {}
}

export class ClubStandardsSetCategory implements Action {
  readonly type = ClubStandardsActionTypes.ClubStandardsSetCategory;
  constructor(public category: string) {}
}

export type ClubStandardsAction =
  | LoadClubStandards
  | ClubStandardsLoaded
  | ClubStandardsLoadError
  | ClubStandardsSetGender
  | ClubStandardsSetCategory;

export const fromClubStandardsActions = {
  LoadClubStandards,
  ClubStandardsLoaded,
  ClubStandardsLoadError,
  ClubStandardsSetGender,
  ClubStandardsSetCategory,
};
