import { createFeatureSelector, createSelector } from '@ngrx/store';
import { MagicMile } from '../models/magic-mile.model';
import * as magicMileReducer from './magic-mile.reducer';

const getMagicMileState = createFeatureSelector<magicMileReducer.State>(magicMileReducer.FEATURE_KEY);

const getCallState = createSelector(getMagicMileState, (state: magicMileReducer.State) => state.callState);

const getError = createSelector(getMagicMileState, (state: magicMileReducer.State) => state.callState);

const getAllMagicMile = createSelector(getMagicMileState, getCallState, (state: magicMileReducer.State) => state.list);

const getSelectedId = createSelector(getMagicMileState, (state: magicMileReducer.State) => state.selectedId);

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
  getCallState,
  getError,
  getAllMagicMile,
  getSelectedMagicMile,
  getMagicMileSearch,
};
