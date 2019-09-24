import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { debounceTime, distinctUntilChanged, startWith } from 'rxjs/operators';
import { Store } from '@ngrx/store';
import { Subject } from 'rxjs';

import { fromSearchActions } from '../../+state/search.actions';
import { SearchPartialState } from '../../+state/search.reducer';

@Component({
  selector: 'bpj-search-bar',
  templateUrl: './search-bar.component.html',
  styleUrls: [ './search-bar.component.scss' ],
})
export class SearchBarComponent implements OnInit {
  @Input() debounce: number;
  @Input() keywords = '';
  @Input() placeholder = 'Search...';

  @Output() search = new EventEmitter<string>();

  inputChanged = new Subject<string>();

  constructor(private store$: Store<SearchPartialState>) {}

  ngOnInit() {
    this.inputChanged
      .pipe(
        startWith(this.keywords),
        debounceTime(this.debounce),
        distinctUntilChanged()
      )
      .subscribe((input) => {
        this.search.emit(input);
        this.store$.dispatch(new fromSearchActions.Search(input));
      });
  }

  onKeyUp(keywords: string) {
    this.inputChanged.next(keywords);
  }
}
