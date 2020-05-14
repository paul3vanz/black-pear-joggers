import { AmplifyUIAngularModule } from '@aws-amplify/ui-angular';
import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { RouterModule } from '@angular/router';

import { AuthPageComponent } from './containers/auth-page/auth-page.component';

@NgModule({
  declarations: [AuthPageComponent],
  imports: [
    CommonModule,
    RouterModule.forChild([
      {
        path: '',
        component: AuthPageComponent,
      },
    ]),
    AmplifyUIAngularModule,
  ],
})
export class AuthModule {}
