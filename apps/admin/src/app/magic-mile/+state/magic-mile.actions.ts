// import { Action } from '@ngrx/store';
// import { Athlete } from 'apps/race-results/src/app/models/athlete';

// export enum MagicMileActionTypes {
//   LoadAthletes = '[Athletes] Load Athletes',
//   AthletesLoaded = '[Athletes] Athletes Loaded',
//   AthletesLoadError = '[Athletes] Athletes Load Error',
//   SubmitMagicMile = '[Athletes] Submit Athletes',
// }

// export class LoadAthletes implements Action {
//   readonly type = MagicMileActionTypes.LoadAthletes;
//   constructor(public athleteName: string) {}
// }

// export class AthletesLoadError implements Action {
//   readonly type = MagicMileActionTypes.AthletesLoadError;
//   constructor(public payload: any) {}
// }

// export class AthletesLoaded implements Action {
//   readonly type = MagicMileActionTypes.AthletesLoaded;
//   constructor(public athletes: Athlete[]) {}
// }

// export class SubmitMagicMile implements Action {
//   readonly type = MagicMileActionTypes.SubmitMagicMile;
//   constructor(public payload: any) {}
// }

// export type MagicMileAction =
//   | LoadAthletes
//   | AthletesLoaded
//   | AthletesLoadError
//   | SubmitMagicMile;

// export const fromAthletesActions = {
//   LoadAthletes,
//   AthletesLoaded,
//   AthletesLoadError,
//   SubmitMagicMile,
// };
