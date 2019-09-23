import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MagicMilePageComponent } from './containers/magic-mile-page/magic-mile-page.component';
import { RouterModule } from '@angular/router';
import { RecordMagicMileFormComponent } from './components/record-magic-mile-form/record-magic-mile-form.component';
import { ReactiveFormsModule } from '@angular/forms';
import { AthleteSearchResultsComponent } from './components/athlete-search-results/athlete-search-results.component';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { MagicMileDataAccessModule } from '@black-pear-joggers/magic-mile-data-access';

@NgModule({
  declarations: [
    AthleteSearchResultsComponent,
    MagicMilePageComponent,
    RecordMagicMileFormComponent,
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule.forChild([
      {
        path: '',
        component: MagicMilePageComponent,
      }
    ]),
    MagicMileDataAccessModule,
    SharedComponentsModule,
  ]
})
export class MagicMileModule { }
