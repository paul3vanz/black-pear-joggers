import { createSelector } from '@ngrx/store';
import { includedEvents } from '../models/event-with-result.model';
import { Result } from '../models/result.model';
import { resultsReducer } from './results.reducer';


export namespace resultsSelectors {
    class EventWithResult {
        name: string;
        distance: number;
        aliases: string[];
        best: Result;
    }

    export const getState = (state: { [reducer: string]: any }) => state.results;

    export const getLoadingState = createSelector(getState, (state: resultsReducer.State) => state.loadingState);

    export const getResults = createSelector(getState, (state: resultsReducer.State) => state.records);

    export const getPersonalBestsByYearAndCategory = createSelector(getState, (state: resultsReducer.State) => {
        const breakdown = {};

        if (!state.records) {
            return null;
        }

        state.records.data.filter((result) => includedEvents.find((event) => event.aliases.includes(result.event))).forEach((performance) => {
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

            if (breakdown[year].categories[performance.category].races[eventGroup].performance.time_parsed >= performance.timeParsed) {
                breakdown[year].categories[performance.category].races[eventGroup].performance = performance;
            }
        });

        return breakdown;
    });

    export const getCertificate = (year?: number, category?: string) =>
        createSelector(getState, (state: resultsReducer.State) => {
            return null;
        });

    export const getPersonalBests = (year?: number, category?: string) =>
        createSelector(getState, (state: resultsReducer.State) => {
            return state.records
                ? state.records.data
                    .filter((result) => (result.isPersonalBest))
                    .filter((result) => includedEvents.find((event) => event.aliases.includes(result.event)))
                    .filter((result) => (year ? new Date(result.date).getFullYear() === year : true))
                    .filter((result) => (category ? result.category === category : true))
                    .reduce(
                        (accumulatedEvents: EventWithResult[], result) => {
                            const resultByEventIndex = accumulatedEvents.findIndex((r) => r.aliases.includes(result.event));

                            if (
                                !accumulatedEvents[resultByEventIndex].best ||
                                Number(accumulatedEvents[resultByEventIndex].best.timeParsed) > Number(result.timeParsed)
                            ) {
                                accumulatedEvents[resultByEventIndex].best = result;
                            }

                            return accumulatedEvents;
                        },
                        [
                            {
                                name: 'Mile',
                                distance: 1609.34,
                                aliases: ['Mile', '1M'],
                                best: null,
                            },
                            {
                                name: '5K',
                                distance: 5000,
                                aliases: ['5K', 'parkrun'],
                                best: null,
                            },
                            {
                                name: '10K',
                                distance: 10000,
                                aliases: ['10K', '10KMT'],
                                best: null,
                            },
                            {
                                name: 'HM',
                                distance: 21097.5,
                                aliases: ['HM', 'HMMT'],
                                best: null,
                            },
                            {
                                name: 'Mar',
                                distance: 42195,
                                aliases: ['Mar', 'MarMT'],
                                best: null,
                            },
                        ]
                    )
                : null;
        });
}
