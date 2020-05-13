import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AmplifyAngularModule } from 'aws-amplify-angular';

import { FilterAthletesPipe } from './core/pipes/filter-athletes.pipe';
import { AppComponent } from './app.component';
import { NxModule } from '@nrwl/nx';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { HttpClientModule } from '@angular/common/http';
// import { AuthService } from './services/auth.service';
import { StoreModule } from '@ngrx/store';
import { EffectsModule } from '@ngrx/effects';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { environment } from '../environments/environment';
// import { AUTH_FEATURE_KEY } from './state/reducers/auth.reducer';

import * as fromAuth from 'libs/authentication/src/lib/state/reducers/auth.reducer';
import { AuthenticationModule } from '@black-pear-joggers/authentication';
import { MagicMileModule } from './magic-mile/magic-mile.module';
import { AppRoutingModule } from './app.routing.module';

@NgModule({
  declarations: [AppComponent],
  imports: [
    BrowserModule,
    NxModule.forRoot(),
    AppRoutingModule,
    StoreModule.forRoot({
      auth: fromAuth.reducer
    }),
    EffectsModule.forRoot([]),
    StoreDevtoolsModule.instrument({
      maxAge: 25,
      logOnly: environment.production
    }),
    HttpClientModule,
    AmplifyAngularModule,
    SharedComponentsModule,
    AuthenticationModule,
    SharedPipesModule,
    MagicMileModule
  ],
  exports: [],
  bootstrap: [AppComponent]
})
export class AppModule {}
