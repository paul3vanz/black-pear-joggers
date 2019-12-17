import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Athlete } from 'apps/race-results/src/app/models/athlete';

@Component({
  selector: 'bpj-athlete-search-results',
  templateUrl: './athlete-search-results.component.html',
  styleUrls: ['./athlete-search-results.component.scss']
})
export class AthleteSearchResultsComponent {
  @Input() athletes: Athlete[];
  @Input() loading: boolean;
  @Input() currentAthleteId: number;
  @Output() selectAthlete = new EventEmitter<Athlete>();


  constructor() {
    this.athletes = [
      {
        id: 1,
        athlete_id: 1,
        athlete_id_alt: null,
        first_name: 'Paul',
        last_name: 'Evans',
        gender: 'M',
        category: 'V35',
        created_at: null,
        updated_at: null,
        latest_performance: null,
        first_performance: null,
        latest_ranking: null,
      },
      {
        id: 2,
        athlete_id: 2,
        athlete_id_alt: null,
        first_name: 'Jo',
        last_name: 'Evans',
        gender: 'W',
        category: 'V35',
        created_at: null,
        updated_at: null,
        latest_performance: null,
        first_performance: null,
        latest_ranking: null,
      },
      {
        id: 3,
        athlete_id: 3,
        athlete_id_alt: null,
        first_name: 'Test',
        last_name: 'Evans',
        gender: 'W',
        category: 'V55',
        created_at: null,
        updated_at: null,
        latest_performance: null,
        first_performance: null,
        latest_ranking: null,
      },
      {
        id: 4,
        athlete_id: 4,
        athlete_id_alt: null,
        first_name: 'Another',
        last_name: 'Evans',
        gender: 'W',
        category: 'SEN',
        created_at: null,
        updated_at: null,
        latest_performance: null,
        first_performance: null,
        latest_ranking: null,
      }
    ];
  }

  onSelectAthlete(athlete: Athlete) {
    this.selectAthlete.emit(athlete);
    this.athletes = [];
  }

  get shouldShowResults() {
    return this.loading
        ? true
        : this.athletes.length
            ? this.athletes.length === 1 && this.athletes[0].athlete_id === this.currentAthleteId
                ? false
                : true
            : false;
  }
}
