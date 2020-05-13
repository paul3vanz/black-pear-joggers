import {
  Component,
  OnChanges,
  ChangeDetectionStrategy,
  Input,
  Output,
  EventEmitter,
  SimpleChanges
} from '@angular/core';

import { Athlete } from '@black-pear-joggers/race-results-data-access';

@Component({
  selector: 'bpj-athletes-table',
  templateUrl: './athletes-table.component.html',
  styleUrls: ['./athletes-table.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AthletesTableComponent {
  @Input() athletes: Athlete[];
  @Output() selectAthlete = new EventEmitter<number>();

  search: string;

  constructor() {}

  onSelectAthlete(athleteId: number) {
    this.selectAthlete.emit(athleteId);
  }
}
