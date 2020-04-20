import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Paging } from '../../models/paging';
import { Result } from '../../models/result';

@Component({
  selector: 'bpj-athlete-results',
  templateUrl: './athlete-results.component.html',
  styleUrls: ['./athlete-results.component.scss']
})
export class AthleteResultsComponent {
  @Input() loading: boolean;
  @Input() year: string;
  @Input() results: Paging<Result>;
  @Output() previous = new EventEmitter();
  @Output() next = new EventEmitter();

  filter: string;
  latestYear: number;
  firstYear: number;
  years: number[] = [];
}
