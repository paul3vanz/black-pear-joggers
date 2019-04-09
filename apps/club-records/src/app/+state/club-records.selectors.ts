import { createFeatureSelector, createSelector } from '@ngrx/store';
import { CLUBRECORDS_FEATURE_KEY, ClubRecordsState } from './club-records.reducer';

// Lookup the 'ClubRecords' feature state managed by NgRx
const getClubRecordsState = createFeatureSelector<ClubRecordsState>(CLUBRECORDS_FEATURE_KEY);

const getLoaded = createSelector(getClubRecordsState, (state: ClubRecordsState) => state.loaded);

const getError = createSelector(getClubRecordsState, (state: ClubRecordsState) => state.error);

const getAllClubRecords = createSelector(getClubRecordsState, getLoaded, (state: ClubRecordsState, isLoaded) => {
  return isLoaded ? state.list : [];
});

const getSelectedClubRecord = createSelector(getClubRecordsState, (state: ClubRecordsState) => state.selected);

const getCategories = createSelector(getClubRecordsState, (clubRecords) => {
  return Array.from(new Set(clubRecords.list.map((record) => record.category)));
});

const getGenders = createSelector(getClubRecordsState, (clubRecords) => {
  return Array.from(new Set(clubRecords.list.map((record) => record.gender)));
});

export const clubRecordsQuery = {
  getLoaded,
  getError,
  getAllClubRecords,
  getSelectedClubRecord,
  getCategories,
  getGenders,
};
