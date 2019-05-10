import { Injectable } from '@angular/core';
import { Actions, Effect } from '@ngrx/effects';
import { switchMap, map } from 'rxjs/operators';
import { StandardsActionsTypes, GetAction, GetSuccessAction, GetFailAction } from '../actions/standards';
import { StandardsService } from '../services/standards.service';

@Injectable()
export class StandardsEffects {
  @Effect()
  getStandards$ = this.actions$
    .ofType(StandardsActionsTypes.GET)
    .pipe(
      switchMap((action: GetAction) =>
        this.standardsService
          .getStandards(action.payload.gender, action.payload.category)
          .pipe(map((standards) => new GetSuccessAction(standards)))
      )
    );

  constructor(private actions$: Actions, private standardsService: StandardsService) {}
}
