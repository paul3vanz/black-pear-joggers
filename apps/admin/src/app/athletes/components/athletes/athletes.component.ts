import { Component, OnInit, Input } from '@angular/core';
import {
  LoadingState,
  Athlete
} from '@black-pear-joggers/race-results-data-access';

@Component({
  selector: 'bpj-athletes',
  templateUrl: './athletes.component.html',
  styleUrls: ['./athletes.component.scss']
})
export class AthletesComponent implements OnInit {
  @Input() loadingState: LoadingState;
  @Input() athletes: Athlete[];

  constructor() {}

  ngOnInit() {}
}
