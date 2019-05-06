import { Action } from '@ngrx/store';
import { Standard } from '../models/standard.model';

export enum ClubStandardsActionTypes {
  LoadClubStandards = '[Club Standards] Load',
  ClubStandardsLoaded = '[Club Standards] Loaded',
  ClubStandardsLoadError = '[Club Standards] Load Error',
  ClubStandardsSetGender = '[Club Standards] Set Gender',
  ClubStandardsSetCategory = '[Club Standards] Set Category',
  ClubStandardsClaimStart = '[Club Standards] Start Claim',
  ClubStandardsClaimSubmit = '[Club Standards] Submit Claim',
  ClubStandardsClaimSubmitSuccess = '[Club Standards] Submit Claim Success',
  ClubStandardsClaimSubmitError = '[Club Standards] Submit Claim Error',
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

export class ClubStandardsClaimStart implements Action {
  readonly type = ClubStandardsActionTypes.ClubStandardsClaimStart;
}

export class ClubStandardsClaimSubmit implements Action {
  readonly type = ClubStandardsActionTypes.ClubStandardsClaimSubmit;
  constructor(public payload: any) {}
}
export class ClubStandardsClaimSubmitSuccess implements Action {
  readonly type = ClubStandardsActionTypes.ClubStandardsClaimSubmitSuccess;
  constructor(public payload: any) {}
}
export class ClubStandardsClaimSubmitError implements Action {
  readonly type = ClubStandardsActionTypes.ClubStandardsClaimSubmitError;
  constructor(public payload: any) {}
}

export type ClubStandardsAction =
  | LoadClubStandards
  | ClubStandardsLoaded
  | ClubStandardsLoadError
  | ClubStandardsSetGender
  | ClubStandardsSetCategory
  | ClubStandardsClaimStart
  | ClubStandardsClaimSubmit
  | ClubStandardsClaimSubmitSuccess
  | ClubStandardsClaimSubmitError;

export const fromClubStandardsActions = {
  LoadClubStandards,
  ClubStandardsLoaded,
  ClubStandardsLoadError,
  ClubStandardsSetGender,
  ClubStandardsSetCategory,
  ClubStandardsClaimStart,
  ClubStandardsClaimSubmit,
  ClubStandardsClaimSubmitSuccess,
  ClubStandardsClaimSubmitError,
};
