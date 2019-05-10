import { environment } from './../environments/environment';
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { StoreModule } from '@ngrx/store';
import { RouterModule } from '@angular/router';

import { AppComponent } from './app.component';

import { ResultsService } from './services/results.service';
import { AthletesService } from './services/athletes.service';
import { StandardsService } from './services/standards.service';

import { AthletePageComponent } from './containers/athlete-page/athlete-page.component';
import { MeetingPageComponent } from './containers/meeting-page/meeting-page.component';
import { SearchPageComponent } from './containers/search-page/search-page.component';
import { StandardsPageComponent } from './containers/standards-page/standards-page.component';

import { StandardsTableComponent } from './components/standards-table/standards-table.component';
import { ResultsSummaryTableComponent } from './components/results-summary-table/results-summary-table.component';

import { reducers } from './reducers';
import { AthletePageModule } from './containers/athlete-page/athlete-page.module';
import { PipesModule } from './pipes/pipes.module';
import { AthletesEffects } from './effects/athletes.effects';
import { EffectsModule } from '@ngrx/effects';
import { ResultsEffects } from './effects/results.effects';
import { StandardsEffects } from './effects/standards.effects';
import { MeetingPageModule } from './containers/meeting-page/meeting-page.module';
import { SearchPageModule } from './containers/search-page/search-page.module';
import { StandardsPageModule } from './containers/standards-page/standards-page.module';
import { HttpClientModule } from '@angular/common/http';
import { NxModule } from '@nrwl/nx';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';

@NgModule({
  declarations: [ AppComponent, ResultsSummaryTableComponent, StandardsTableComponent ],
  imports: [
    StoreModule.forRoot(reducers),
    StoreDevtoolsModule.instrument({
      maxAge: 25,
      logOnly: environment.production,
    }),
    EffectsModule.forRoot([ AthletesEffects, ResultsEffects, StandardsEffects ]),
    BrowserModule,
    NxModule.forRoot(),
    FormsModule,
    HttpClientModule,
    PipesModule,
    SharedComponentsModule,

    AthletePageModule,
    MeetingPageModule,
    SearchPageModule,
    StandardsPageModule,

    RouterModule.forRoot(
      [
        {
          path: '',
          redirectTo: '/results',
          pathMatch: 'full',
        },
        {
          path: 'results',
          component: SearchPageComponent,
        },
        {
          path: 'standards',
          component: StandardsPageComponent,
        },
        {
          path: 'athlete/:id',
          component: AthletePageComponent,
        },
        {
          path: 'meeting/:date/:id',
          component: MeetingPageComponent,
        },
      ],
      {
        useHash: true,
      }
    ),
  ],
  providers: [ AthletesService, ResultsService, StandardsService ],
  bootstrap: [ AppComponent ],
})
export class AppModule {}
