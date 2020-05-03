import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Athlete } from '../../models/athlete';

@Component({
  selector: 'bpj-search-results-athletes',
  templateUrl: './search-results-athletes.component.html',
  styleUrls: ['./search-results-athletes.component.css']
})
export class SearchResultsAthletesComponent {
  @Input() athletes: Athlete[];
  @Input() keywords: string;
  @Input() searching: boolean;

  @Output() addAthlete = new EventEmitter();
}
