import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ClubStandardsDataAccessModule } from '@black-pear-joggers/club-standards-data-access';
import { ClubStandardsPageComponent } from './containers/club-standards-page/club-standards-page.component';
import { AwardClaimTableComponent } from './components/award-claim-table/award-claim-table.component';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { EditAwardClaimModalComponent } from './components/edit-award-claim-modal/edit-award-claim-modal.component';

@NgModule({
  imports: [
    CommonModule,
    RouterModule.forChild([
      {
        path: '',
        component: ClubStandardsPageComponent,
      },
    ]),
    ClubStandardsDataAccessModule,
    SharedComponentsModule,
    SharedPipesModule,
  ],
  declarations: [ ClubStandardsPageComponent, AwardClaimTableComponent, EditAwardClaimModalComponent ],
})
export class ClubStandardsModule {}
