import { createFeatureSelector, createSelector } from '@ngrx/store';

import { athletesSelectors } from '@black-pear-joggers/race-results-data-access';
import { membershipSelectors } from '@black-pear-joggers/membership-data-access';

export namespace membershipCompositeSelectors {
  export const getAllMembershipWithAthlete = createSelector(
    athletesSelectors.getAllRecords,
    membershipSelectors.getAllMembership,
    (athletes, memberships) =>
      memberships.map((member) => ({
        ...member,
        athlete: athletes.find((athlete) => athlete.id === 450606 && member.Urn === '3127917'),
      }))
  );
}
