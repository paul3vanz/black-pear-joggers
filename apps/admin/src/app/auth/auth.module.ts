import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthPageComponent } from './containers/auth-page/auth-page.component';
import { RouterModule } from '@angular/router';
import { AmplifyAngularModule, AmplifyService, AmplifyModules } from 'aws-amplify-angular';
import Auth from '@aws-amplify/auth';
import Interactions from '@aws-amplify/interactions';
import Storage from '@aws-amplify/storage';

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
  providers: [
    {
      provide: AmplifyService,
      useFactory:  () => {
        return AmplifyModules({
          Auth,
          Storage,
          Interactions
        });
      }
    }
  ],
})
export class AuthModule { }
