import { createFeatureSelector, createSelector } from '@ngrx/store';

import * as moment from 'moment-mini-ts';

import { Ranking } from '../models/ranking.model';
import { rankingsReducer } from './rankings.reducer';
import { YearRankingStats } from '../models/ranking-stats.model';

export namespace rankingsSelectors {
  export const selectState = createFeatureSelector<any, rankingsReducer.State>(rankingsReducer.FEATURE_KEY);

  export const selectAllRecords = createSelector(selectState, (state): Ranking[] => state.records);

  export const selectLoading = createSelector(selectState, (state) => state.loadingState);

  export const getYears = createSelector(selectAllRecords, (allRecords) => {
    return [...new Set(allRecords.map((ranking) => moment(ranking.date).year()))];
  });

  export const getRankingsByYear = createSelector(selectAllRecords, (allRecords: Ranking[], year: number) => {
    return allRecords.filter((ranking) => moment(ranking.date).year() === year);
  });

  export const getStats = createSelector(selectAllRecords, (allRecords) => {
    return allRecords
      .slice()
      .sort((a, b) => (new Date(a.date) < new Date(b.date) ? 0 : -1))
      .reduce(
        (accumulator, currentValue) => {
          const year = new Date(currentValue.date).getFullYear();

          const currentYearIndex = accumulator.findIndex((value) => value.year === year);

          if (currentYearIndex === -1) {
            accumulator.push({
              year: year,
              highest: currentValue,
              lowest: currentValue,
              first: currentValue,
              last: currentValue,
              improvement: { number: null, percentage: null },
            });
          } else {
            if (currentValue.ranking > accumulator[currentYearIndex].highest.ranking) {
              accumulator[currentYearIndex].highest = currentValue;
            }
            if (currentValue.ranking < accumulator[currentYearIndex].lowest.ranking) {
              accumulator[currentYearIndex].lowest = currentValue;
            }
            if (new Date(currentValue.date) > new Date(accumulator[currentYearIndex].last.date)) {
              accumulator[currentYearIndex].last = currentValue;
            }
            if (new Date(currentValue.date) < new Date(accumulator[currentYearIndex].first.date)) {
              accumulator[currentYearIndex].first = currentValue;
            }
          }

          return accumulator;
        },
        [] as YearRankingStats[]
      )
      .map((rankingStat) => {
        const improvement = rankingStat.last.ranking - rankingStat.first.ranking;

        return {
          ...rankingStat,
          improvement: {
            number: -improvement,
            percentage: -(improvement / rankingStat.first.ranking),
          },
        };
      });
  });
}
