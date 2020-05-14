import { CommonModule } from '@angular/common';
import { EffectsModule } from '@ngrx/effects';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import { AthleteDetailsModalComponent } from './components/athlete-details-modal/athlete-details-modal.component';
import { AthletesComponent } from './components/athletes/athletes.component';
import { AthletesPageComponent } from './containers/athletes-page/athletes-page.component';
import { AthletesPageEffects } from './effects/athletes-page.effects';
import { AthletesTableComponent } from './components/athletes-table/athletes-table.component';
import { AuthenticatedGuard } from 'libs/authentication/src/lib/guards/authenticated.guard';
import { FilterAthletesPipe } from '../core/pipes/filter-athletes.pipe';
import { RaceResultsDataAccessModule } from '@black-pear-joggers/race-results-data-access';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';

@NgModule({
  declarations: [AthletesPageComponent, AthletesComponent, AthleteDetailsModalComponent, AthletesTableComponent, FilterAthletesPipe],
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
        canActivate: [AuthenticatedGuard],
      },
    ]),
    RaceResultsDataAccessModule,
    SharedComponentsModule,
    SharedPipesModule,
  ],
})
export class AthletesModule {}
