import { Component, OnInit } from '@angular/core';
import { Subject, Observable } from 'rxjs';
import { Store } from '@ngrx/store';

import { distinctUntilChanged, debounceTime, filter } from 'rxjs/operators';
import { Event } from '../../models/event';
import { Paging } from '../../models/paging';
import { Athlete } from '../../models/athlete';

import * as rootReducer from '../../reducers';
import * as athleteActions from '../../actions/athletes';
import * as eventsActions from '../../actions/events';

@Component({
  selector: 'bpj-results-page',
  templateUrl: './search-page.component.html',
  styleUrls: [ './search-page.component.css' ],
})
export class SearchPageComponent implements OnInit {
  athletesLoading$: Observable<boolean>;
  athletes$: Observable<Paging<Athlete>>;
  eventsLoading$: Observable<boolean>;
  events$: Observable<Paging<Event>>;
  searchTerm$: Subject<string> = new Subject<string>();
  searchTermTemp = '';
  showAddAthleteModal = false;

  constructor(private store$: Store<rootReducer.State>) {
    this.athletesLoading$ = this.store$.select((store) => store.athletes.loading);
  }

  ngOnInit() {
    this.athletes$ = this.store$.select((store) => store.athletes.athletes);
    this.events$ = this.store$.select((store) => store.events.events);

    this.searchTerm$.pipe(debounceTime(500), distinctUntilChanged(), filter((term) => term.length >= 3)).subscribe((term) => {
      this.store$.dispatch(new athleteActions.SearchAction(term));
      this.store$.dispatch(new eventsActions.SearchAction(term));
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
