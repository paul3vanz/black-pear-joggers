import { Component, Input, OnChanges } from '@angular/core';
import { MagicMile } from '@black-pear-joggers/magic-mile-data-access';

@Component({
  selector: 'bpj-results-table',
  templateUrl: './results-table.component.html',
  styleUrls: [ './results-table.component.scss' ],
})
export class ResultsTableComponent implements OnChanges {
  @Input() results: MagicMile[];
  @Input() resultsPerPage = 100;
  @Input() sort: string;
  currentPage = 1;
  sortedResults: MagicMile[];

  ngOnChanges() {
    if (this.sort === 'fastest') {
      this.sortedResults = this.results.slice(0).sort((result1, result2) => (result1.actualTimeParsed < result2.actualTimeParsed ? -1 : 0));
    } else {
      this.sortedResults = this.results;
    }
  }

  previousPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
    }
  }

  nextPage() {
    if (this.endRecord < this.results.length) {
      this.currentPage++;
    }
  }

  get startRecord() {
    return this.resultsPerPage * this.currentPage - this.resultsPerPage + 1;
  }

  get endRecord() {
    const endRecord = this.resultsPerPage * this.currentPage;

    return endRecord > this.results.length ? this.results.length : endRecord;
  }
}
