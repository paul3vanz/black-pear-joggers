// import { MagicMileAction, MagicMileActionTypes } from './magic-mile.actions';
// import { Athlete } from 'apps/race-results/src/app/models/athlete';
// import { LoadingState, LoadingStates } from 'libs/authentication/src/lib/models/loading-state.model';

// export const MAGICMILE_FEATURE_KEY = 'magicMile';

// export interface MagicMileState {
//   athletes: Athlete[];
//   loadingState: LoadingState;
// }

// export interface MagicMilePartialState {
//   readonly [MAGICMILE_FEATURE_KEY]: MagicMileState;
// }

// export const initialState: MagicMileState = {
//   athletes: [],
//   loadingState: LoadingStates.INIT,
// };

// export function magicMileReducer(
//   state: MagicMileState = initialState,
//   action: MagicMileAction
// ): MagicMileState {
//   switch (action.type) {
//     case MagicMileActionTypes.AthletesLoaded: {
//       state = {
//         ...state,
//         athletes: action.athletes,
//         loadingState: LoadingStates.LOADED,
//       };
//       break;
//     }
//   }
//   return state;
// }
