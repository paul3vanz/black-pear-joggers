import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { NxModule } from '@nrwl/nx';

import { AppComponent } from './app.component';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { HttpClientModule } from '@angular/common/http';
import { StandardsFormComponent } from './components/standards-form/standards-form.component';
import { StoreModule } from '@ngrx/store';
import { EffectsModule } from '@ngrx/effects';
import {
  CLUBSTANDARDS_FEATURE_KEY,
  initialState as clubStandardsInitialState,
  clubStandardsReducer,
} from './+state/club-standards.reducer';
import { ClubStandardsEffects } from './+state/club-standards.effects';
import { environment } from '../environments/environment';
import { storeFreeze } from 'ngrx-store-freeze';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { ClaimAwardModalComponent } from './components/claim-award-modal/claim-award-modal.component';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { ClaimStepCategoryDetailsComponent } from './components/claim-step-category-details/claim-step-category-details.component';
import { ClaimStepRacesComponent } from './components/claim-step-races/claim-step-races.component';
import { ClaimStepPersonalDetailsComponent } from './components/claim-step-personal-details/claim-step-personal-details.component';
import { PacePipe } from 'apps/club-records/src/app/pipes/pace.pipe';

@NgModule({
  declarations: [
    AppComponent,
    StandardsFormComponent,
    ClaimAwardModalComponent,
    ClaimStepCategoryDetailsComponent,
    ClaimStepRacesComponent,
    ClaimStepPersonalDetailsComponent,
    PacePipe,
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule,
    NxModule.forRoot(),
    SharedComponentsModule,
    StoreModule.forRoot(
      { clubStandards: clubStandardsReducer },
      {
        initialState: { clubStandards: clubStandardsInitialState },
        metaReducers: !environment.production ? [ storeFreeze ] : [],
      }
    ),
    EffectsModule.forRoot([ ClubStandardsEffects ]),
    !environment.production ? StoreDevtoolsModule.instrument() : [],
  ],
  providers: [],
  bootstrap: [ AppComponent ],
})
export class AppModule {}
