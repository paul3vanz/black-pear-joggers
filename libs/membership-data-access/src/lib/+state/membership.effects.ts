import { Actions, createEffect, ofType } from '@ngrx/effects';
import { EMPTY, of } from 'rxjs';
import { catchError, map, mergeMap } from 'rxjs/operators';

import { Injectable } from '@angular/core';
import { MembershipService } from '../services/membership.service';
import { membershipActions } from './membership.actions';

@Injectable()
export class MembershipEffects {
  loadResults$ = createEffect(() =>
    this.actions$.pipe(
      ofType(membershipActions.loadMembership),
      mergeMap(() =>
        this.membershipService.fetchMembers(1606).pipe(
          map((memberships) => membershipActions.loadMembershipSuccess({ memberships })),
          catchError(() => EMPTY)
        )
      )
    )
  );

  constructor(private actions$: Actions, private membershipService: MembershipService) {}
}
