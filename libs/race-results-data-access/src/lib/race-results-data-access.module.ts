import { CommonModule } from '@angular/common';
import { EffectsModule } from '@ngrx/effects';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { StoreModule } from '@ngrx/store';

import { AthletesEffects } from './+state/athletes.effects';
import { athletesReducer } from './+state/athletes.reducer';
import { AthletesService } from './services/athletes.service';
import { CompetitiveStatusPipe } from './pipes/competitive-status.pipe';
import { RankingsEffects } from './+state/rankings.effects';
import { rankingsReducer } from './+state/rankings.reducer';
import { RankingsService } from './services/rankings.service';

@NgModule({
  declarations: [CompetitiveStatusPipe],
  imports: [
    CommonModule,
    HttpClientModule,
    StoreModule.forFeature(
      athletesReducer.ATHLETES_FEATURE_KEY,
      athletesReducer.reducer,
      { initialState: athletesReducer.initialState }
    ),
    StoreModule.forFeature(
      rankingsReducer.FEATURE_KEY,
      rankingsReducer.reducer,
      { initialState: rankingsReducer.initialState }
    ),
    EffectsModule.forFeature([AthletesEffects, RankingsEffects])
  ],
  providers: [AthletesService, RankingsService],
  exports: [CompetitiveStatusPipe]
})
export class RaceResultsDataAccessModule {}
