import {
  Component,
  Input,
  ChangeDetectionStrategy,
  EventEmitter,
  Output
} from '@angular/core';
import {
  LoadingState,
  Athlete,
  Ranking
} from '@black-pear-joggers/race-results-data-access';

@Component({
  selector: 'bpj-athletes',
  templateUrl: './athletes.component.html',
  styleUrls: ['./athletes.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AthletesComponent {
  @Input() athlete: Athlete;
  @Input() athletes: Athlete[];
  @Input() rankings: Ranking[];
  @Input() rankingsLoadingState: LoadingState;
  @Input() loadingState: LoadingState;

  @Output() selectAthlete = new EventEmitter<number>();

  onSelectAthlete(athleteId: number) {
    this.selectAthlete.emit(athleteId);
  }
}
