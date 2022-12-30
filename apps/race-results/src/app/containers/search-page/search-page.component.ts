import * as eventsActions from '../../actions/meetings';
import * as rootReducer from '../../reducers';
import { Athlete } from '../../models/athlete';
import { athletesActions, athletesSelectors, LoadingState } from '@black-pear-joggers/race-results-data-access';
import { Component, OnInit } from '@angular/core';
import { debounceTime, distinctUntilChanged, filter } from 'rxjs/operators';
import { getLoading } from '../../reducers/meetings';
import { Meeting } from '../../models/meeting';
import { Observable, Subject } from 'rxjs';
import { Paging } from '../../models/paging';
import { Store } from '@ngrx/store';



@Component({
    selector: 'bpj-results-page',
    templateUrl: './search-page.component.html',
    styleUrls: ['./search-page.component.css']
})
export class SearchPageComponent implements OnInit {
    athletesLoadingState$: Observable<LoadingState>;
    athletes$: Observable<Athlete[]>;
    meetingsLoadingState$: Observable<boolean>;
    meetings$: Observable<Paging<Meeting>>;
    searchTerm$: Subject<string> = new Subject<string>();
    searchTermTemp = '';
    showAddAthleteModal = false;

    constructor(private store$: Store<rootReducer.State>) {
        this.athletesLoadingState$ = this.store$.select(
            athletesSelectors.getLoadingState
        );

        this.meetingsLoadingState$ = this.store$.select(getLoading);
    }

    ngOnInit() {
        this.athletes$ = this.store$.select(athletesSelectors.getAllRecords);
        this.meetings$ = this.store$.select(store => store.events.events);

        this.searchTerm$
            .pipe(
                debounceTime(500),
                distinctUntilChanged(),
                filter(keywords => keywords.length >= 3 || !keywords)
            )
            .subscribe(keywords => {
                if (keywords) {
                    this.store$.dispatch(athletesActions.search({ keywords }));
                    this.store$.dispatch(new eventsActions.SearchAction(keywords));
                } else {
                    this.store$.dispatch(new eventsActions.SearchAction(''));
                }
            });

        const savedSearch = this.recallSearch();

        if (savedSearch) {
            this.search(savedSearch);
        } else {
            this.store$.dispatch(new eventsActions.SearchAction(''));
        }
    }

    search(term: string): void {
        this.storeSearch(term);
        this.searchTermTemp = term;
        this.searchTerm$.next(term);
    }

    recallSearch(): string {
        try {
            return localStorage ? localStorage.getItem('bpj.results.search') : '';
        } catch (e) {
            // localStorage not available
        }
    }

    storeSearch(term: string) {
        try {
            localStorage.setItem('bpj.results.search', term);
        } catch (e) {
            // localStorage not available
        }
    }
}
