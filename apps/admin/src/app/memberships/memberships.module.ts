import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { AuthenticatedGuard } from 'libs/authentication/src/lib/guards/authenticated.guard';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { CommonModule } from '@angular/common';
import { MatSortModule } from '@angular/material/sort';
import { MatTableModule } from '@angular/material/table';
import { MembershipDataAccessModule } from '@black-pear-joggers/membership-data-access';
import { MembershipsComponent } from './components/memberships/memberships.component';
import { MembershipsPageComponent } from './containers/memberships-page/memberships-page.component';
import { NgModule } from '@angular/core';
import { RaceResultsDataAccessModule } from '@black-pear-joggers/race-results-data-access';
import { RouterModule } from '@angular/router';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';

@NgModule({
  declarations: [MembershipsPageComponent, MembershipsComponent],
  imports: [
    CommonModule,
    FormsModule,
    MatSortModule,
    MatTableModule,
    ReactiveFormsModule,
    RouterModule.forChild([
      {
        path: '',
        component: MembershipsPageComponent,
        canActivate: [AuthenticatedGuard],
      },
    ]),
    MembershipDataAccessModule,
    RaceResultsDataAccessModule,
    SharedComponentsModule,
  ],
})
export class MembershipsModule {}
