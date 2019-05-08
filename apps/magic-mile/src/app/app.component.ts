import { Component, OnInit, OnDestroy, ElementRef, ViewChild } from '@angular/core';
import { Store } from '@ngrx/store';
import { Observable, Subject } from 'rxjs';
import { magicMileQuery, MagicMileState, Entity } from '@black-pear-joggers/magic-mile-data-access';
import { Load, Search, SetYear } from 'libs/magic-mile-data-access/src/lib/+state/magic-mile.actions';

@Component({
  selector: 'bpj-root',
  templateUrl: './app.component.html',
  styleUrls: [ './app.component.scss' ],
})
export class AppComponent implements OnInit, OnDestroy {
  title = 'app';
  keywords$: Observable<string>;
  loaded$: Observable<boolean>;
  error$: Observable<any>;
  results$: Observable<Entity[]>;
  years$: Observable<any>;
  currentYear$: Observable<number>;
  destroyed$ = new Subject<boolean>();
  @ViewChild('table') table: ElementRef;

  constructor(private store$: Store<MagicMileState>) {
    this.loaded$ = this.store$.select(magicMileQuery.getLoaded);
    this.error$ = this.store$.select(magicMileQuery.getError);
    this.results$ = this.store$.select(magicMileQuery.getAllMagicMile);
    // this.keywords$ = this.store$.select(magicMileReducer.getFilterName);
    // this.years$ = this.store$.select(magicMileReducer.getYears);
    // this.currentYear$ = this.store$.select(magicMileReducer.getFilterYear);
  }

  ngOnInit() {
    this.store$.dispatch(new Load());

    const savedSearch = localStorage.getItem('bpj.magic-mile.search');
    if (savedSearch) {
      this.store$.dispatch(new Search(savedSearch));
    }
  }

  onSearch(keywords: string) {
    this.store$.dispatch(new Search(keywords));
  }

  pageChanged(page: number) {
    this.table.nativeElement.scrollIntoView();
  }

  setYear(year: string) {
    this.store$.dispatch(new SetYear(year));
  }

  ngOnDestroy() {
    this.destroyed$.next(true);
    this.destroyed$.complete();
  }
}
