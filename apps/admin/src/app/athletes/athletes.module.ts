import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { AthletesPageComponent } from './containers/athletes-page/athletes-page.component';
import { RaceResultsDataAccessModule } from '@black-pear-joggers/race-results-data-access';
import { AthletesComponent } from './components/athletes/athletes.component';
import { HttpClientModule } from '@angular/common/http';
import { AthleteDetailsModalComponent } from './components/athlete-details-modal/athlete-details-modal.component';
import { AthletesTableComponent } from './components/athletes-table/athletes-table.component';
import { FilterAthletesPipe } from '../core/pipes/filter-athletes.pipe';
import { EffectsModule } from '@ngrx/effects';
import { AthletesPageEffects } from './effects/athletes-page.effects';

@NgModule({
  declarations: [
    AthletesPageComponent,
    AthletesComponent,
    AthleteDetailsModalComponent,
    AthletesTableComponent,
    FilterAthletesPipe
  ],
  imports: [
    CommonModule,
    EffectsModule.forFeature([AthletesPageEffects]),
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule.forChild([
      {
        path: '',
        component: AthletesPageComponent,
        canActivate: []
      }
    ]),
    RaceResultsDataAccessModule,
    SharedComponentsModule,
    SharedPipesModule
  ]
})
export class AthletesModule {}
