import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RankingsService } from './services/rankings.service';
import { StoreModule } from '@ngrx/store';
import * as athletesReducer from './+state/athletes.reducer';
import * as rankingsReducer from './+state/rankings.reducer';
import { EffectsModule } from '@ngrx/effects';
import { RankingsEffects } from './+state/rankings.effects';
import { AthletesEffects } from './+state/athletes.effects';
import { HttpClientModule } from '@angular/common/http';
import { AthletesService } from './services/athletes.service';

@NgModule({
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
  providers: [AthletesService, RankingsService]
})
export class RaceResultsDataAccessModule {}
