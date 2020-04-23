import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RankingsService } from './services/rankings.service';
import { StoreModule } from '@ngrx/store';
import * as rankingsReducer from './+state/rankings.reducer';
import { EffectsModule } from '@ngrx/effects';
import { RankingsEffects } from './+state/rankings.effects';

@NgModule({
  imports: [
    CommonModule,
    StoreModule.forFeature(
      rankingsReducer.FEATURE_KEY,
      rankingsReducer.reducer,
      { initialState: rankingsReducer.initialState }
    ),
    EffectsModule.forFeature([RankingsEffects])
  ],
  providers: [RankingsService]
})
export class RaceResultsDataAccessModule {}
