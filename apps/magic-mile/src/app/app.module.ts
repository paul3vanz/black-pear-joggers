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
import { MagicMilePageComponent } from './containers/magic-mile-page/magic-mile-page.component';
import { PipesModule } from './pipes/pipes.module';
import { SearchBarComponent } from './components/search-bar/search-bar.component';
import { ResultsTableComponent } from './components/results-table/results-table.component';
import { MagicMileDataAccessModule } from '@black-pear-joggers/magic-mile-data-access';

@NgModule({
  declarations: [ AppComponent, MagicMilePageComponent, SearchBarComponent, ResultsTableComponent ],
  imports: [
    BrowserAnimationsModule,
    BrowserModule,
    EffectsModule.forRoot([]),
    HttpClientModule,
    NxModule.forRoot(),
    PipesModule,
    RouterModule.forRoot([
      {
        path: '',
        component: MagicMilePageComponent,
      },
    ]),
    SharedComponentsModule,
    StoreModule.forRoot({}),
    StoreDevtoolsModule.instrument({
      maxAge: 25,
      logOnly: environment.production,
    }),
    MagicMileDataAccessModule,
  ],
  providers: [],
  bootstrap: [ AppComponent ],
})
export class AppModule {}
