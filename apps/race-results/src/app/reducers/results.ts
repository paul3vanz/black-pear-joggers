import { createSelector } from '@ngrx/store';

import { includedEvents } from '../models/event-with-result';
import { Paging } from '../models/paging';
import { Result } from '../models/result';
import { ResultsActions, ResultsActionsTypes } from '../actions/results';

export interface State {
  loading: boolean;
  results: Paging<Result>;
  selected: Result;
}

export const initialState: State = {
  loading: false,
  results: null,
  selected: null,
};

export function reducer(state = initialState, action: ResultsActions): State {
  switch (action.type) {
    case ResultsActionsTypes.GET:
      return {
        ...state,
        loading: true,
      };
    case ResultsActionsTypes.GET_SUCCESS:
      return {
        ...state,
        loading: false,
        results: action.payload,
      };
    case ResultsActionsTypes.GET_FAIL:
      return {
        ...state,
        loading: false,
      };
    default:
      return state;
  }
}

class EventWithResult {
  name: string;
  distance: number;
  aliases: string[];
  best: Result;
}

export const getState = (state: { [reducer: string]: any }) => state.results;

export const getLoading = createSelector(getState, (state: State) => state.loading);

export const getResults = createSelector(getState, (state: State) => state.results);

export const getPersonalBestsByYearAndCategory = createSelector(getState, (state: State) => {
  const breakdown = {};

  if (!state.results) {
    return null;
  }

  state.results.data.filter((result) => includedEvents.find((event) => event.aliases.includes(result.event))).forEach((performance) => {
    const year = new Date(performance.date).getFullYear();

    const eventGroup = includedEvents.find((event) => event.aliases.includes(performance.event)).name;

    breakdown[year] = breakdown[year] || {
      year,
      categories: {},
    };

    breakdown[year].categories[performance.category] = breakdown[year].categories[performance.category] || {
      category: performance.category,
      races: {},
    };

    breakdown[year].categories[performance.category].races[eventGroup] = breakdown[year].categories[performance.category].races[
      eventGroup
    ] || {
      race: eventGroup,
      performance: performance,
    };

    if (breakdown[year].categories[performance.category].races[eventGroup].performance.time_parsed >= performance.time_parsed) {
      breakdown[year].categories[performance.category].races[eventGroup].performance = performance;
    }
  });

  console.log(breakdown);

  return breakdown;
});

export const getCertificate = (year?: number, category?: string) =>
  createSelector(getState, (state: State) => {
    return null;
  });

export const getPersonalBests = (year?: number, category?: string) =>
  createSelector(getState, (state: State) => {
    return state.results
      ? state.results.data
          .filter((result) => includedEvents.find((event) => event.aliases.includes(result.event)))
          .filter((result) => (year ? new Date(result.date).getFullYear() === year : true))
          .filter((result) => (category ? result.category === category : true))
          .reduce(
            (accumulatedEvents: EventWithResult[], result) => {
              const resultByEventIndex = accumulatedEvents.findIndex((r) => r.aliases.includes(result.event));

              if (
                !accumulatedEvents[resultByEventIndex].best ||
                Number(accumulatedEvents[resultByEventIndex].best.time_parsed) > Number(result.time_parsed)
              ) {
                accumulatedEvents[resultByEventIndex].best = result;
              }

              return accumulatedEvents;
            },
            [
              {
                name: 'Mile',
                distance: 1609.34,
                aliases: [ 'Mile', '1M' ],
                best: null,
              },
              {
                name: '5K',
                distance: 5000,
                aliases: [ '5K', 'parkrun' ],
                best: null,
              },
              {
                name: '10K',
                distance: 10000,
                aliases: [ '10K', '10KMT' ],
                best: null,
              },
              {
                name: 'HM',
                distance: 21097.5,
                aliases: [ 'HM', 'HMMT' ],
                best: null,
              },
              {
                name: 'Mar',
                distance: 42195,
                aliases: [ 'Mar', 'MarMT' ],
                best: null,
              },
            ]
          )
      : null;
  });
