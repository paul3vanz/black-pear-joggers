import * as rootReducer from '../../reducers';
import { ActivatedRoute, Params } from '@angular/router';
import { athletesActions, Result } from '@black-pear-joggers/race-results-data-access';
import { Component, OnInit } from '@angular/core';
import { Paging } from '../../models/paging';
import { ResultsService } from '../../services/results.service';
import { Store } from '@ngrx/store';
import { switchMap } from 'rxjs/operators';



@Component({
    selector: 'bpj-meeting-page',
    templateUrl: './meeting-page.component.html',
    styleUrls: ['./meeting-page.component.css']
})
export class MeetingPageComponent implements OnInit {
    results: Paging<Result>;

    constructor(
        private resultsService: ResultsService,
        private route: ActivatedRoute,
        private store$: Store<rootReducer.State>
    ) { }

    ngOnInit(): void {
        this.getResults();
    }

    getResults(): void {
        this.route.params
            .pipe(
                switchMap((params: Params) =>
                    this.resultsService.getMeetingResults(params['date'], params['id'])
                )
            )
            .subscribe(results => (this.results = results));
    }

    selectAthlete(athleteId: number) {
        this.store$.dispatch(athletesActions.select({ athleteId }));
    }
}
