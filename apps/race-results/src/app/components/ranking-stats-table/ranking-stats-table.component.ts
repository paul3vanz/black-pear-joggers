import {
  Component,
  OnInit,
  ChangeDetectionStrategy,
  Input
} from '@angular/core';
import { YearRankingStats } from 'libs/race-results-data-access/src/lib/models/ranking-stats.model';

@Component({
  selector: 'bpj-ranking-stats-table',
  templateUrl: './ranking-stats-table.component.html',
  styleUrls: ['./ranking-stats-table.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RankingStatsTableComponent implements OnInit {
  @Input() rankingsStats: YearRankingStats[];

  constructor() {}

  ngOnInit() {}
}
