import { createFeatureSelector, createSelector } from '@ngrx/store';
import { MAGICMILE_FEATURE_KEY, MagicMileState } from './magic-mile.reducer';
import { MagicMile } from '../models/magic-mile.model';

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
const getMagicMileSearch = (keywords: string) => {
  return createSelector(getAllMagicMile, (magicMile) => {
    const searchProperties = [ 'firstName', 'lastName' ];
    const keywordArray = keywords && keywords.split(' ');
    return keywords
      ? magicMile.filter((result: MagicMile) => {
          return keywordArray.every((keyword) =>
            searchProperties.some((property) => result[property].toLowerCase().includes(keyword.toLowerCase()))
          );
        })
      : magicMile;
  });
};

export const magicMileQuery = {
  getLoaded,
  getError,
  getAllMagicMile,
  getSelectedMagicMile,
  getMagicMileSearch,
};
