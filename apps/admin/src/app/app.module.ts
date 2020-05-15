import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AppComponent } from './app.component';
import { NxModule } from '@nrwl/nx';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { HttpClientModule } from '@angular/common/http';
import { EffectsModule } from '@ngrx/effects';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { environment } from '../environments/environment';

import { MagicMileModule } from './magic-mile/magic-mile.module';
import { AppRoutingModule } from './app.routing.module';
import { AuthenticationModule } from 'libs/authentication/src/lib/authentication.module';

@NgModule({
  declarations: [AppComponent],
  imports: [
    BrowserModule,
    NxModule.forRoot(),
    AppRoutingModule,
    EffectsModule.forRoot([]),
    StoreDevtoolsModule.instrument({
      maxAge: 25,
      logOnly: environment.production,
    }),
    HttpClientModule,
    SharedComponentsModule,
    AuthenticationModule,
    SharedPipesModule,
    MagicMileModule,
  ],
  exports: [],
  bootstrap: [AppComponent],
})
export class AppModule {}
