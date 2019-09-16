import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MagicMilePageComponent } from './containers/magic-mile-page/magic-mile-page.component';
import { RouterModule } from '@angular/router';
import { RecordMagicMileFormComponent } from './components/record-magic-mile-form/record-magic-mile-form.component';
import { ReactiveFormsModule } from '@angular/forms';
import { StoreModule } from '@ngrx/store';
import { EffectsModule } from '@ngrx/effects';
import { MAGICMILE_FEATURE_KEY, initialState as magicMileInitialState, magicMileReducer } from './+state/magic-mile.reducer';
import { MagicMileEffects } from './+state/magic-mile.effects';
import { AthleteSearchResultsComponent } from './components/athlete-search-results/athlete-search-results.component';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';

@NgModule({
  declarations: [MagicMilePageComponent, RecordMagicMileFormComponent, AthleteSearchResultsComponent],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule.forChild([
      {
        path: '',
        component: MagicMilePageComponent,
      }
    ]),
    StoreModule.forFeature(MAGICMILE_FEATURE_KEY, magicMileReducer, { initialState: magicMileInitialState }),
    EffectsModule.forFeature([MagicMileEffects]),
    SharedComponentsModule,
  ]
})
export class MagicMileModule { }
