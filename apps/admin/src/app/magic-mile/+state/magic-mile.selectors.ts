// import { createFeatureSelector, createSelector } from '@ngrx/store';
// import { MAGICMILE_FEATURE_KEY, MagicMileState } from './magic-mile.reducer';

// // Lookup the 'MagicMile' feature state managed by NgRx
// const getMagicMileState = createFeatureSelector<MagicMileState>(
//   MAGICMILE_FEATURE_KEY
// );

// const getLoadingState = createSelector(
//   getMagicMileState,
//   (state: MagicMileState) => state.loadingState
// );

// const getSearchedAthletes = createSelector(
//   getMagicMileState,
//   getLoadingState,
//   (state: MagicMileState, isLoaded) => {
//     console.log('get search');
//     return isLoaded ? state.athletes : [];
//   }
// );

// export const magicMileQuery = {
//   getLoadingState,
//   getSearchedAthletes,
// };
