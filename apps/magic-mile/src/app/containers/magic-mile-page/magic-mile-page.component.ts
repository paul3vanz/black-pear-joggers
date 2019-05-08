import { Component, OnInit, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { Entity, magicMileQuery, MagicMileState, magicMileReducer } from '@black-pear-joggers/magic-mile-data-access';
import { Store } from '@ngrx/store';
import { Load, Search, SetYear } from 'libs/magic-mile-data-access/src/lib/+state/magic-mile.actions';

@Component({
  selector: 'bpj-magic-mile-page',
  templateUrl: './magic-mile-page.component.html',
  styleUrls: [ './magic-mile-page.component.scss' ],
})
export class MagicMilePageComponent implements OnInit, OnDestroy {
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
    // this.keywords$ = this.store$.select(msagicMileReducer.getFilterName);
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
