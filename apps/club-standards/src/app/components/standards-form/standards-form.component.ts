import { Component, OnInit, Input } from '@angular/core';
import { Store } from '@ngrx/store';
import { fromClubStandardsActions } from '../../+state/club-standards.actions';
import { Observable } from 'rxjs';
import { clubStandardsQuery } from '../../+state/club-standards.selectors';

@Component({
  selector: 'bpj-standards-form',
  templateUrl: './standards-form.component.html',
  styleUrls: [ './standards-form.component.scss' ],
})
export class StandardsFormComponent implements OnInit {
  standards$: Observable<any>;
  activeGender$: Observable<string>;
  activeCategory$: Observable<string>;
  loaded$: Observable<boolean>;
  error$: Observable<boolean>;
  displayFormat: string;

  genders = [ 'M', 'W' ];

  categories = [ 'U20', 'U23', 'SEN', 'V35', 'V40', 'V45', 'V50', 'V55', 'V60', 'V65', 'V70', 'V75', 'V80' ];

  displayFormats = [ { label: 'Time', value: 'time' }, { label: 'Pace (min/mile)', value: 'pace' } ];

  constructor(private store$: Store<any>) {}

  ngOnInit() {
    this.standards$ = this.store$.select(clubStandardsQuery.getStandardsByEvent);
    this.activeGender$ = this.store$.select(clubStandardsQuery.getActiveGender);
    this.activeCategory$ = this.store$.select(clubStandardsQuery.getActiveCategory);
    this.loaded$ = this.store$.select(clubStandardsQuery.getLoaded);
    this.error$ = this.store$.select(clubStandardsQuery.getError);
    this.displayFormat = 'time';

    this.store$.dispatch(new fromClubStandardsActions.LoadClubStandards('M', 'SEN'));
  }

  onSelectGender(gender: string) {
    this.store$.dispatch(new fromClubStandardsActions.ClubStandardsSetGender(gender));
  }

  onSelectCategory(category: string) {
    this.store$.dispatch(new fromClubStandardsActions.ClubStandardsSetCategory(category));
  }

  onSelectDisplayFormat(format: string) {
    this.displayFormat = format;
  }
}
