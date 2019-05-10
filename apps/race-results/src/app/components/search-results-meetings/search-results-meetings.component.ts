import { Component, Input, OnChanges } from '@angular/core';

import { Event } from '../../models/event';
import { Paging } from '../../models/paging';

@Component({
  selector: 'bpj-search-results-meetings',
  templateUrl: './search-results-meetings.component.html',
  styleUrls: [ './search-results-meetings.component.css' ],
})
export class SearchResultsMeetingsComponent implements OnChanges {
  @Input() Events: Paging<Event>;
  @Input() keywords: string;
  @Input() searching: boolean;
  pages: number[];

  ngOnChanges(changes: any): void {
    if (!changes.Events || !changes.Events.currentValue) {
      return;
    }
    const pageCount: number = changes.Events.currentValue.last_page;
    this.pages = [];
    for (let i = 1; i <= pageCount; i++) {
      this.pages.push(i);
    }
  }
}
