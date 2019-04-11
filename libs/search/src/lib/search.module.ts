import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SearchBarComponent } from './components/search-bar/search-bar.component';
import { StoreModule } from '@ngrx/store';
import { EffectsModule } from '@ngrx/effects';
import { FormsModule } from '@angular/forms';
import { SEARCH_FEATURE_KEY, initialState as searchInitialState, searchReducer } from './+state/search.reducer';
import { SearchEffects } from './+state/search.effects';

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    StoreModule.forFeature(SEARCH_FEATURE_KEY, searchReducer, {
      initialState: searchInitialState,
    }),
    EffectsModule.forFeature([ SearchEffects ]),
  ],
  declarations: [ SearchBarComponent ],
  exports: [ SearchBarComponent ],
})
export class SearchModule {}
