import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { StoreModule } from '@ngrx/store';
import { EffectsModule } from '@ngrx/effects';
import {
  MAGICMILE_FEATURE_KEY,
  initialState as magicMileInitialState,
  magicMileReducer
} from './+state/magic-mile.reducer';
import { MagicMileEffects } from './+state/magic-mile.effects';

@NgModule({
  imports: [
    CommonModule,
    StoreModule.forFeature(MAGICMILE_FEATURE_KEY, magicMileReducer, {
      initialState: magicMileInitialState
    }),
    EffectsModule.forFeature([MagicMileEffects])
  ]
})
export class MagicMileDataAccessModule {}
