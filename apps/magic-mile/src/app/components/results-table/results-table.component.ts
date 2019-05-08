import { Component, Input, OnChanges } from '@angular/core';
import { MagicMile } from 'libs/magic-mile-data-access/src/lib/models/magic-mile.model';

@Component({
  selector: 'bpj-results-table',
  templateUrl: './results-table.component.html',
  styleUrls: [ './results-table.component.scss' ],
})
export class ResultsTableComponent implements OnChanges {
  @Input() results: MagicMile[];
  @Input() loading: boolean;
  @Input() keywords: string;

  currentPage: number;
  totalPages: number;
  pageSize = 50;

  constructor() {}

  ngOnChanges() {
    this.currentPage = 1;
  }
}
