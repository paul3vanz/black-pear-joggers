import { CommonModule } from '@angular/common';
import { EffectsModule } from '@ngrx/effects';
import { NgModule } from '@angular/core';
import { StoreModule } from '@ngrx/store';

import { ClubRecordsEffects } from './+state/club-records.effects';
import { ClubRecordsService } from './services/club-records.service';

import * as clubRecordsReducer from './+state/club-records.reducer';

@NgModule({
  imports: [
    CommonModule,
    StoreModule.forFeature(
      clubRecordsReducer.CLUB_RECORDS_FEATURE_KEY,
      clubRecordsReducer.reducer,
      {
        initialState: clubRecordsReducer.initialState
      }
    ),
    EffectsModule.forFeature([ClubRecordsEffects])
  ],
  providers: [ClubRecordsService]
})
export class ClubRecordsDataAccessModule {}
