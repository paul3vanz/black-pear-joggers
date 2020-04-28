import { createFeatureSelector, createSelector } from '@ngrx/store';
import {
  CLUB_RECORDS_FEATURE_KEY,
  ClubRecordsState
} from './club-records.reducer';
import { searchQuery } from '@black-pear-joggers/search';

// Lookup the 'ClubRecords' feature state managed by NgRx
const getClubRecordsState = createFeatureSelector<ClubRecordsState>(
  CLUB_RECORDS_FEATURE_KEY
);

const getLoaded = createSelector(
  getClubRecordsState,
  (state: ClubRecordsState) => {
    return state.loaded;
  }
);

const getError = createSelector(
  getClubRecordsState,
  (state: ClubRecordsState) => state.error
);

const getAllClubRecords = createSelector(
  getClubRecordsState,
  searchQuery.getKeywords,
  (state: ClubRecordsState, keywords) => {
    return (
      (keywords
        ? state.records.filter(record => {
            return [
              record.first_name,
              record.last_name,
              record.date,
              record.race,
              `${record.first_name} ${record.last_name} ${record.date} ${
                record.race
              }`
            ].some(field => !!field.match(new RegExp(keywords, 'i')));
          })
        : state.records) || []
    );
  }
);

const getClubRecordsByAthlete = (athleteId: number) =>
  createSelector(getAllClubRecords, clubRecords => {
    return clubRecords.filter(record => record.athlete_id == athleteId);
  });

const getSelectedClubRecord = createSelector(
  getClubRecordsState,
  (state: ClubRecordsState) => state.selected
);

const getCategories = createSelector(getClubRecordsState, clubRecords => {
  return Array.from(
    new Set(clubRecords.records.map(record => record.category))
  );
});

const getGenders = createSelector(getClubRecordsState, clubRecords => {
  return Array.from(new Set(clubRecords.records.map(record => record.gender)));
});

const getYears = createSelector(getClubRecordsState, clubRecords => {
  return Array.from(
    new Set(
      clubRecords.records.map(record => new Date(record.date).getFullYear())
    )
  );
});

export const clubRecordsQuery = {
  getLoaded,
  getError,
  getAllClubRecords,
  getClubRecordsByAthlete,
  getSelectedClubRecord,
  getCategories,
  getGenders,
  getYears
};
