import { Component, Output, EventEmitter, Input } from '@angular/core';
import { Store } from '@ngrx/store';
import { SearchPartialState } from '../../+state/search.reducer';
import { fromSearchActions } from '../../+state/search.actions';

@Component({
  selector: 'bpj-search-bar',
  templateUrl: './search-bar.component.html',
  styleUrls: [ './search-bar.component.scss' ],
})
export class SearchBarComponent {
  @Input() placeholder = 'Search...';
  @Output() search = new EventEmitter<string>();

  constructor(private store$: Store<SearchPartialState>) {}

  onChange(keywords: string) {
    this.search.emit(keywords);
    this.store$.dispatch(new fromSearchActions.Search(keywords));
  }
}
