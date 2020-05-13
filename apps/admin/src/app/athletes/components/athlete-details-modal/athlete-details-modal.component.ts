import {
  Component,
  OnInit,
  ChangeDetectionStrategy,
  Input
} from '@angular/core';
import {
  Athlete,
  Ranking,
  LoadingState
} from '@black-pear-joggers/race-results-data-access';

@Component({
  selector: 'bpj-athlete-details-modal',
  templateUrl: './athlete-details-modal.component.html',
  styleUrls: ['./athlete-details-modal.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AthleteDetailsModalComponent implements OnInit {
  @Input() athlete: Athlete;
  @Input() rankings: Ranking[];
  @Input() rankingsLoadingState: LoadingState;
  @Input() open: boolean;

  constructor() {}

  ngOnInit() {}

  get latestRanking(): Ranking {
    return this.rankings.sort((a, b) => (a.date < b.date ? -1 : 0)).pop();
  }

  get lastUpdated(): string {
    return this.rankings
      .sort((a, b) => (a.updated_at < b.updated_at ? -1 : 0))
      .pop().updated_at;
  }
}
