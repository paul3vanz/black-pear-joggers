import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { BrowserModule } from '@angular/platform-browser';
import { EffectsModule } from '@ngrx/effects';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { NxModule } from '@nrwl/nx';
import { RouterModule } from '@angular/router';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { StoreModule } from '@ngrx/store';

import { AppComponent } from './app.component';
import { environment } from '../environments/environment';
import {
  initialState as magicMileInitialState,
  magicMileReducer
} from './+state/magic-mile.reducer';
import { MagicMileEffects } from './+state/magic-mile.effects';
import { MagicMilePageComponent } from './containers/magic-mile-page/magic-mile-page.component';
import { PipesModule } from './pipes/pipes.module';
import { SearchBarComponent } from './components/search-bar/search-bar.component';
import { ResultsTableComponent } from './components/results-table/results-table.component';
import { SearchBarModule } from './components/search-bar/search-bar.module';

@NgModule({
  declarations: [AppComponent, MagicMilePageComponent, ResultsTableComponent],
  imports: [
    SearchBarModule,
    BrowserAnimationsModule,
    BrowserModule,
    EffectsModule.forRoot([MagicMileEffects]),
    HttpClientModule,
    NxModule.forRoot(),
    PipesModule,
    RouterModule.forRoot([
      {
        path: '',
        component: MagicMilePageComponent
      }
    ]),
    SharedComponentsModule,
    StoreModule.forRoot(magicMileReducer, {
      initialState: magicMileInitialState
    }),
    StoreDevtoolsModule.instrument({
      maxAge: 25,
      logOnly: environment.production
    }),
    SearchBarModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {}
