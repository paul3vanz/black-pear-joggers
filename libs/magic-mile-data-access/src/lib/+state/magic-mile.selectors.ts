import { createFeatureSelector, createSelector } from '@ngrx/store';
import { MAGICMILE_FEATURE_KEY, MagicMileState } from './magic-mile.reducer';

// Lookup the 'MagicMile' feature state managed by NgRx
const getMagicMileState = createFeatureSelector<MagicMileState>(MAGICMILE_FEATURE_KEY);

const getLoaded = createSelector(getMagicMileState, (state: MagicMileState) => state.loaded);
const getError = createSelector(getMagicMileState, (state: MagicMileState) => state.error);

const getAllMagicMile = createSelector(getMagicMileState, getLoaded, (state: MagicMileState, isLoaded) => {
  return isLoaded ? state.list : [];
});
const getSelectedId = createSelector(getMagicMileState, (state: MagicMileState) => state.selectedId);
const getSelectedMagicMile = createSelector(getAllMagicMile, getSelectedId, (magicMile, id) => {
  const result = magicMile.find((it) => it['id'] === id);
  return result ? Object.assign({}, result) : undefined;
});

export const magicMileQuery = {
  getLoaded,
  getError,
  getAllMagicMile,
  getSelectedMagicMile,
};
