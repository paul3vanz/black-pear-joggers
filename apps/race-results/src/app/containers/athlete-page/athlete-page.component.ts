import * as rootReducer from '../../reducers';
import * as standardsReducer from '../../reducers/standards';
import { ActivatedRoute } from '@angular/router';
import { Athlete } from '../../models/athlete';
import { athletesActions, athletesSelectors, LoadingState } from '@black-pear-joggers/race-results-data-access';
import { ClubRecord, clubRecordsActions, clubRecordsQuery } from '@black-pear-joggers/club-records-data-access';
import { Component, OnInit } from '@angular/core';
import { Meeting } from '../../models/meeting';
import { Observable } from 'rxjs';
import { Paging } from '../../models/paging';
import { Ranking } from '@black-pear-joggers/race-results-data-access';
import { rankingsSelectors } from '@black-pear-joggers/race-results-data-access';
import { Result } from '../../models/result';
import { Standard } from '../../models/standard';
import { Store } from '@ngrx/store';
import { YearRankingStats } from 'libs/race-results-data-access/src/lib/models/ranking-stats.model';

import { rankingsActions } from 'libs/race-results-data-access/src/lib/+state/rankings.actions';



import { resultsReducer } from 'libs/race-results-data-access/src/lib/+state/results.reducer';
import { resultsSelectors } from 'libs/race-results-data-access/src/lib/+state/results.selectors';
import { resultsActions } from 'libs/race-results-data-access/src/lib/+state/results.actions';

@Component({
    selector: 'bpj-athlete-page',
    templateUrl: './athlete-page.component.html',
    styleUrls: ['./athlete-page.component.css'],
})
export class AthletePageComponent implements OnInit {
    athleteLoadingState$: Observable<LoadingState>;
    athlete$: Observable<Athlete>;
    resultsLoadingState$: Observable<LoadingState>;
    results$: Observable<Paging<Result>>;
    rankings$: Observable<Ranking[]>;
    rankingsStats$: Observable<YearRankingStats[]>;
    personalBests$: Observable<any>;
    standardsLoading$: Observable<boolean>;
    standards$: Observable<Standard[]>;
    meetings$: Observable<Paging<Meeting>>;
    recordsLoaded$: Observable<boolean>;
    records$: Observable<ClubRecord[]>;

    constructor(private route: ActivatedRoute, private store$: Store<rootReducer.State>) {
        this.athleteLoadingState$ = this.store$.select(athletesSelectors.getLoadingState);
        this.athlete$ = this.store$.select(athletesSelectors.getSelectedRecord);

        this.athlete$.subscribe(console.log);

        this.resultsLoadingState$ = this.store$.select(resultsSelectors.getLoadingState);
        this.results$ = this.store$.select(resultsSelectors.getResults);
        this.rankings$ = this.store$.select(rankingsSelectors.selectAllRecords);
        this.rankingsStats$ = this.store$.select(rankingsSelectors.getStats);
        this.personalBests$ = this.store$.select(resultsSelectors.getPersonalBests());

        this.recordsLoaded$ = this.store$.select(clubRecordsQuery.getLoaded);
        this.records$ = this.store$.select(clubRecordsQuery.getClubRecordsByAthlete(this.route.snapshot.params['id']));

        this.standardsLoading$ = this.store$.select((store) => store.standards.loading);
        this.standards$ = this.store$.select(standardsReducer.getStandards);
    }

    ngOnInit(): void {
        this.route.params.subscribe(({ id }) => {
            const athleteId = parseInt(id);

            this.store$.dispatch(athletesActions.load({ athleteId }));
            this.store$.dispatch(athletesActions.select({ athleteId }));
            this.store$.dispatch(rankingsActions.load({ athleteId }));
            this.store$.dispatch(clubRecordsActions.load());
            this.store$.dispatch(resultsActions.load({ athleteId }));
        });
    }
}
