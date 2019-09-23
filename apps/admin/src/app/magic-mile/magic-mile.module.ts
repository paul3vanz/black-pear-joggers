import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MagicMilePageComponent } from './containers/magic-mile-page/magic-mile-page.component';
import { RouterModule } from '@angular/router';
import { RecordMagicMileFormComponent } from './components/record-magic-mile-form/record-magic-mile-form.component';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { AthleteSearchResultsComponent } from './components/athlete-search-results/athlete-search-results.component';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { MagicMileDataAccessModule } from '@black-pear-joggers/magic-mile-data-access';
import { AuthenticatedGuard } from 'libs/authentication/src/lib/guards/authenticated.guard';
import { DeleteMagicMileFormComponent } from './components/delete-magic-mile-form/delete-magic-mile-form.component';

@NgModule({
  declarations: [
    AthleteSearchResultsComponent,
    MagicMilePageComponent,
    RecordMagicMileFormComponent,
    DeleteMagicMileFormComponent,
  ],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule.forChild([
      {
        path: '',
        component: MagicMilePageComponent,
        canActivate: [ AuthenticatedGuard ],
      }
    ]),
    MagicMileDataAccessModule,
    SharedComponentsModule,
  ]
})
export class MagicMileModule { }
