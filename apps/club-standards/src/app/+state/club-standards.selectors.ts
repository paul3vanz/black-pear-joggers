import { createFeatureSelector, createSelector } from '@ngrx/store';
import { CLUBSTANDARDS_FEATURE_KEY, ClubStandardsState } from './club-standards.reducer';

const getClubStandardsState = createFeatureSelector<ClubStandardsState>(CLUBSTANDARDS_FEATURE_KEY);

const getLoaded = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.loaded);
const getError = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.error);

const getActiveGender = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.activeGender);
const getActiveCategory = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.activeCategory);

const getAllClubStandards = createSelector(getClubStandardsState, getLoaded, (state: ClubStandardsState, isLoaded) => {
  return isLoaded ? state.list : [];
});

const getStandardsByEvent = createSelector(getClubStandardsState, (state: ClubStandardsState) => {
  if (!state.list) {
    return null;
  }
  const output: Array<any> = [ { events: [] } ];
  let currentEvent: string = null;
  let currentAward: string = null;
  let currentEventIndex = -1;
  let currentAwardIndex = -1;
  state.list.forEach((s) => {
    if (currentEvent !== s.event) {
      ++currentEventIndex;
      currentEvent = s.event;
      output[currentEventIndex] = { name: currentEvent, standards: [] };
      currentAwardIndex = -1;
    }
    if (currentAward !== s.name) {
      ++currentAwardIndex;
      currentAward = s.name;
      output[currentEventIndex].standards[currentAwardIndex] = { name: s.name, time: s.time, timeParsed: s.time_parsed };
    }
  });
  return output;
});

export const clubStandardsQuery = {
  getLoaded,
  getError,
  getAllClubStandards,
  getActiveGender,
  getActiveCategory,
  getStandardsByEvent,
};
