import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthPageComponent } from './containers/auth-page/auth-page.component';
import { RouterModule } from '@angular/router';
import { AmplifyAngularModule } from 'aws-amplify-angular';

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
    AmplifyAngularModule,
  ],
})
export class AuthModule { }
