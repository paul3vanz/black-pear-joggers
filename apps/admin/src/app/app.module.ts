import { AppComponent } from './app.component';
import { AppRoutingModule } from './app.routing.module';
import { AuthenticationModule } from 'libs/authentication/src/lib/authentication.module';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { BrowserModule } from '@angular/platform-browser';
import { EffectsModule } from '@ngrx/effects';
import { HttpClientModule } from '@angular/common/http';
import { MagicMileModule } from './magic-mile/magic-mile.module';
import { NgModule } from '@angular/core';
import { NxModule } from '@nrwl/nx';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { environment } from '../environments/environment';

@NgModule({
  declarations: [AppComponent],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
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
