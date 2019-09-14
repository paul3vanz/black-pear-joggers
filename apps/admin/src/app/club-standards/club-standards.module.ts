import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ClubStandardsDataAccessModule } from '@black-pear-joggers/club-standards-data-access';
import { ClubStandardsPageComponent } from './containers/club-standards-page/club-standards-page.component';
import { AwardClaimTableComponent } from './components/award-claim-table/award-claim-table.component';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { EditAwardClaimModalComponent } from './components/edit-award-claim-modal/edit-award-claim-modal.component';
import { ValidationCheckModalComponent } from './components/validation-check-modal/validation-check-modal.component';
import { ViewRacesModalComponent } from './components/view-races-modal/view-races-modal.component';
import { InlineEditFieldComponent } from './components/inline-edit-field/inline-edit-field.component';
import { AuthenticatedGuard } from 'libs/authentication/src/lib/guards/authenticated.guard';

@NgModule({
  imports: [
    CommonModule,
    RouterModule.forChild([
      {
        path: '',
        component: ClubStandardsPageComponent,
        canActivate: [ AuthenticatedGuard ],
      },
    ]),
    ClubStandardsDataAccessModule,
    SharedComponentsModule,
    SharedPipesModule,
  ],
  declarations: [
    ClubStandardsPageComponent,
    AwardClaimTableComponent,
    EditAwardClaimModalComponent,
    ViewRacesModalComponent,
    ValidationCheckModalComponent,
    InlineEditFieldComponent,
  ],
})
export class ClubStandardsModule {}
