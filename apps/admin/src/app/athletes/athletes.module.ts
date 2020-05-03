import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { ReactiveFormsModule } from '@angular/forms';
import { AthletesPageComponent } from './containers/athletes-page/athletes-page.component';
import { RaceResultsDataAccessModule } from '@black-pear-joggers/race-results-data-access';
import { AthletesComponent } from './components/athletes/athletes.component';
import { HttpClientModule } from '@angular/common/http';

@NgModule({
  declarations: [AthletesPageComponent, AthletesComponent],
  imports: [
    CommonModule,
    HttpClientModule,
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
