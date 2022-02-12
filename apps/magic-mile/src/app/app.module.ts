import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { BrowserModule } from '@angular/platform-browser';
import { EffectsModule } from '@ngrx/effects';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { NxModule } from '@nrwl/angular';
import { RouterModule } from '@angular/router';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { StoreModule } from '@ngrx/store';

import { AppComponent } from './app.component';
import { environment } from '../environments/environment';
import { MagicMilePageComponent } from './containers/magic-mile-page/magic-mile-page.component';
import { ResultsTableComponent } from './components/results-table/results-table.component';
import { MagicMileDataAccessModule } from '@black-pear-joggers/magic-mile-data-access';
import { SearchModule } from '@black-pear-joggers/search';
import { SharedPipesModule } from 'libs/shared-pipes/src';

@NgModule({
  declarations: [AppComponent, MagicMilePageComponent, ResultsTableComponent],
  imports: [
    BrowserAnimationsModule,
    BrowserModule,
    EffectsModule.forRoot([]),
    HttpClientModule,
    NxModule.forRoot(),
    RouterModule.forRoot(
      [
        {
          path: '',
          component: MagicMilePageComponent,
        },
      ],
      { relativeLinkResolution: 'legacy' }
    ),
    StoreModule.forRoot({}),
    StoreDevtoolsModule.instrument({
      maxAge: 25,
      logOnly: environment.production,
    }),
    MagicMileDataAccessModule,
    SharedComponentsModule,
    SharedPipesModule,
    SearchModule,
  ],
  providers: [],
  bootstrap: [AppComponent],
})
export class AppModule {}
