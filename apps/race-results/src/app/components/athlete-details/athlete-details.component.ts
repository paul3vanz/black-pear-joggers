import { Component, Input } from '@angular/core';

import { Athlete } from '../../models/athlete';
import { LoadingState } from '@black-pear-joggers/race-results-data-access';

@Component({
  selector: 'bpj-athlete-details',
  templateUrl: './athlete-details.component.html',
  styleUrls: ['./athlete-details.component.scss']
})
export class AthleteDetailsComponent {
  @Input() athlete: Athlete;
  @Input() loadingState: LoadingState;
  @Input() personalBests: any;
  multipleCategoriesInYear: boolean;
  activeYear = '';
  activeCategory = '';

  onChangeTab(year: string, category: string) {
    if (this.activeYear === year && this.activeCategory === category) {
      this.activeYear = null;
      this.activeCategory = null;
      return;
    }

    this.activeYear = year;
    this.activeCategory = category;
  }

  scrollToActiveTab() {
    const activeTab = document.querySelector('.pbs__heading.active');

    if (activeTab) {
      activeTab.scrollIntoView({
        behavior: 'smooth'
      });
    }
  }
}
