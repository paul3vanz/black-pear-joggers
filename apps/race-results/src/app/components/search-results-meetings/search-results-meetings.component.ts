import { Component, Input, OnChanges } from '@angular/core';
import { Meeting } from '../../models/meeting';
import { Paging } from '../../models/paging';


@Component({
    selector: 'bpj-search-results-meetings',
    templateUrl: './search-results-meetings.component.html',
    styleUrls: ['./search-results-meetings.component.css'],
})
export class SearchResultsMeetingsComponent implements OnChanges {
    @Input() meetings: Paging<Meeting>;
    @Input() keywords: string;
    @Input() searching: boolean;
    pages: number[];

    ngOnChanges(changes: any): void {
        if (!changes.meetings || !changes.meetings.currentValue) {
            return;
        }
        const pageCount: number = changes.meetings.currentValue.last_page;
        this.pages = [];
        for (let i = 1; i <= pageCount; i++) {
            this.pages.push(i);
        }
    }
}
