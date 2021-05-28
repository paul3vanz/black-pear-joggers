import { Athlete, athletesActions, athletesSelectors } from '@black-pear-joggers/race-results-data-access';
import { Component, OnInit } from '@angular/core';
import { membershipActions, membershipSelectors } from '@black-pear-joggers/membership-data-access';

import { LoadingState } from '@black-pear-joggers/authentication';
import { Membership } from 'libs/membership-data-access/src/lib/models/membership.model';
import { Observable } from 'rxjs';
import { Store } from '@ngrx/store';
import { membershipCompositeSelectors } from '../../../core/selectors/membership-composite.selectors';

@Component({
  selector: 'bpj-memberships-page',
  templateUrl: './memberships-page.component.html',
  styleUrls: ['./memberships-page.component.scss'],
})
export class MembershipsPageComponent implements OnInit {
  athletesLoadingState$: Observable<LoadingState>;
  athletes$: Observable<Athlete[]>;
  memberships$: Observable<Membership[]>;
  membershipsLoadingState$: Observable<LoadingState>;

  constructor(private store$: Store<any>) {
    this.athletesLoadingState$ = this.store$.select(athletesSelectors.getLoadingState);
    this.memberships$ = this.store$.select(membershipCompositeSelectors.getAllMembershipWithAthlete);
    this.membershipsLoadingState$ = this.store$.select(membershipSelectors.getCallState);

    this.memberships$.subscribe(console.log);
  }

  ngOnInit(): void {
    this.store$.dispatch(athletesActions.load({}));
    this.store$.dispatch(membershipActions.loadMembership());
  }
}
