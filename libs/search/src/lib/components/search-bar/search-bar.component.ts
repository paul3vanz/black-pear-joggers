import { Component, Output, EventEmitter, Input, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import { SearchPartialState } from '../../+state/search.reducer';
import { fromSearchActions } from '../../+state/search.actions';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

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
    this.inputChanged.pipe(distinctUntilChanged(), debounceTime(this.debounce)).subscribe((input) => this.onSearch(input));
  }

  onChange(keywords: string) {
    this.inputChanged.next(keywords);
  }

  onSearch(keywords: string) {
    this.search.emit(keywords);
    this.store$.dispatch(new fromSearchActions.Search(keywords));
  }
}
