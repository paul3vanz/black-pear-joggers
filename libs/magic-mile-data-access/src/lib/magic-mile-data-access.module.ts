import { CommonModule } from '@angular/common';
import { EffectsModule } from '@ngrx/effects';
import { NgModule } from '@angular/core';
import { StoreModule } from '@ngrx/store';

import { MagicMileEffects } from './+state/magic-mile.effects';

import * as magicMileReducer from './+state/magic-mile.reducer';

@NgModule({
  imports: [
    CommonModule,
    StoreModule.forFeature(magicMileReducer.FEATURE_KEY, magicMileReducer.reducer, {
      initialState: magicMileReducer.initialState,
    }),
    EffectsModule.forFeature([ MagicMileEffects ]),
  ],
})
export class MagicMileDataAccessModule {}
