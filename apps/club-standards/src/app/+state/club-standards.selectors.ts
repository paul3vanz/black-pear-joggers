import { createFeatureSelector, createSelector } from '@ngrx/store';
import { CLUBSTANDARDS_FEATURE_KEY, ClubStandardsState } from './club-standards.reducer';

const getClubStandardsState = createFeatureSelector<ClubStandardsState>(CLUBSTANDARDS_FEATURE_KEY);

const getLoaded = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.loaded);
const getError = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.error);

const getClaimLoading = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.claim.loading);
const getClaimLoaded = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.claim.loaded);
const getClaimError = createSelector(getClubStandardsState, (state: ClubStandardsState) => state.claim.error);

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
      output[currentEventIndex].standards[currentAwardIndex] = { name: s.name, time: s.time, timeParsed: s.time_parsed, event: s.event };
    }
  });
  return output;
});

const getAwardForEvent = (event: string, timeParsed: number) =>
  createSelector(getClubStandardsState, (state: ClubStandardsState) => {
    const awardOrder = { Bronze: 1, Silver: 2, Gold: 3, Platinum: 4 };

    return state.list.filter((standard) => standard.event === event).filter((standard) => Number(standard.time_parsed) >= timeParsed);
  });

const getStandardForEventAndCategory = (gender: string, category: string) =>
  createSelector(getClubStandardsState, (state: ClubStandardsState) => {
    return state.list.filter((standard) => standard.gender === gender && standard.category === category);
  });

export const clubStandardsQuery = {
  getLoaded,
  getError,
  getClaimLoading,
  getClaimLoaded,
  getClaimError,
  getAllClubStandards,
  getActiveGender,
  getActiveCategory,
  getStandardsByEvent,
  getAwardForEvent,
  getStandardForEventAndCategory,
};
