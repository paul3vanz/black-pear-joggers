import { AppComponent } from './app.component';
import { BrowserModule } from '@angular/platform-browser';
import { ClubRecordsTableComponent } from './components/club-records-table/club-records-table.component';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { NxModule } from '@nrwl/nx';
import { PipesModule } from './pipes/pipes.module';
import { RouterModule } from '@angular/router';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { StoreModule } from '@ngrx/store';
import { FormsModule } from '@angular/forms';
import { EffectsModule } from '@ngrx/effects';
import { initialState as clubRecordsInitialState, clubRecordsReducer } from './+state/club-records.reducer';
import { ClubRecordsEffects } from './+state/club-records.effects';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { environment } from '../environments/environment';
import { StoreRouterConnectingModule } from '@ngrx/router-store';
import { storeFreeze } from 'ngrx-store-freeze';
import { QueryRecordModalComponent } from './components/query-record-modal/query-record-modal.component';

@NgModule({
  declarations: [ AppComponent, ClubRecordsTableComponent, QueryRecordModalComponent ],
  imports: [
    BrowserModule,
    HttpClientModule,
    FormsModule,
    NxModule.forRoot(),
    PipesModule,
    RouterModule.forRoot([], { initialNavigation: 'enabled' }),
    SharedComponentsModule,
    StoreModule.forRoot(
      { clubRecords: clubRecordsReducer },
      {
        initialState: { clubRecords: clubRecordsInitialState },
        metaReducers: !environment.production ? [ storeFreeze ] : [],
      }
    ),
    EffectsModule.forRoot([ ClubRecordsEffects ]),
    !environment.production ? StoreDevtoolsModule.instrument() : [],
    StoreRouterConnectingModule,
  ],
  providers: [],
  bootstrap: [ AppComponent ],
})
export class AppModule {}
