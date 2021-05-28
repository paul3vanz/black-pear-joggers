import * as membershipReducer from './+state/membership.reducer';

import { CommonModule } from '@angular/common';
import { EffectsModule } from '@ngrx/effects';
import { MembershipEffects } from './+state/membership.effects';
import { NgModule } from '@angular/core';
import { StoreModule } from '@ngrx/store';

@NgModule({
  imports: [
    CommonModule,
    StoreModule.forFeature(membershipReducer.FEATURE_KEY, membershipReducer.reducer, {
      initialState: membershipReducer.initialState,
    }),
    EffectsModule.forFeature([MembershipEffects]),
  ],
})
export class MembershipDataAccessModule {}
