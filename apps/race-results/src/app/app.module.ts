import { BrowserModule } from '@angular/platform-browser';
import { EffectsModule } from '@ngrx/effects';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { NxModule } from '@nrwl/nx';
import { RouterModule } from '@angular/router';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { StoreModule } from '@ngrx/store';

import { AppComponent } from './app.component';
import { appRoutes } from './app.routes';
import { AthleteClubRecordsComponent } from './components/athlete-club-records/athlete-club-records.component';
import { AthleteDetailsComponent } from './components/athlete-details/athlete-details.component';
import { AthletePageComponent } from './containers/athlete-page/athlete-page.component';
import { AthleteResultsComponent } from './components/athlete-results/athlete-results.component';
import { AthletesEffects } from '@black-pear-joggers/race-results-data-access';
import { AthletesService } from '@black-pear-joggers/race-results-data-access';
import { AthleteStandardsComponent } from './components/athlete-standards/athlete-standards.component';
import { ClubRecordsDataAccessModule } from '@black-pear-joggers/club-records-data-access';
import { environment } from './../environments/environment';
import { MeetingPageComponent } from './containers/meeting-page/meeting-page.component';
import { NoSearchResultsAthletesComponent } from './components/no-search-results-athletes/no-search-results-athletes.component';
import { NoSearchResultsMeetingsComponent } from './components/no-search-results-meetings/no-search-results-meetings.component';
import { PersonalBestPanelComponent } from './components/personal-best-panel/personal-best-panel.component';
import { PipesModule } from './pipes/pipes.module';
import { RaceResultsDataAccessModule } from '@black-pear-joggers/race-results-data-access';
import { reducers } from './reducers';
import { ResultsEffects } from './effects/results.effects';
import { ResultsService } from './services/results.service';
import { ResultsSummaryTableComponent } from './components/results-summary-table/results-summary-table.component';
import { SearchBarComponent } from './components/search-bar/search-bar/search-bar.component';
import { SearchPageComponent } from './containers/search-page/search-page.component';
import { SearchResultsAthletesComponent } from './components/search-results-athletes/search-results-athletes.component';
import { SearchResultsMeetingsComponent } from './components/search-results-meetings/search-results-meetings.component';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { StandardsEffects } from './effects/standards.effects';
import { StandardsPageComponent } from './containers/standards-page/standards-page.component';
import { StandardsService } from './services/standards.service';
import { StandardsTableComponent } from './components/standards-table/standards-table.component';

@NgModule({
  declarations: [
    AppComponent,
    AthleteClubRecordsComponent,
    AthleteDetailsComponent,
    AthletePageComponent,
    AthleteResultsComponent,
    AthleteStandardsComponent,
    MeetingPageComponent,
    NoSearchResultsAthletesComponent,
    NoSearchResultsMeetingsComponent,
    PersonalBestPanelComponent,
    ResultsSummaryTableComponent,
    SearchBarComponent,
    SearchPageComponent,
    SearchResultsAthletesComponent,
    SearchResultsMeetingsComponent,
    StandardsPageComponent,
    StandardsTableComponent
  ],
  imports: [
    BrowserModule,
    ClubRecordsDataAccessModule,
    EffectsModule.forRoot([AthletesEffects, ResultsEffects, StandardsEffects]),
    FormsModule,
    HttpClientModule,
    NxModule.forRoot(),
    PipesModule,
    RaceResultsDataAccessModule,
    ReactiveFormsModule,
    RouterModule.forRoot(appRoutes, {
      useHash: true
    }),
    SharedComponentsModule,
    SharedPipesModule,
    StoreModule.forRoot(reducers),
    StoreDevtoolsModule.instrument({
      maxAge: 25,
      logOnly: environment.production
    })
  ],
  providers: [AthletesService, ResultsService, StandardsService],
  bootstrap: [AppComponent]
})
export class AppModule {}
