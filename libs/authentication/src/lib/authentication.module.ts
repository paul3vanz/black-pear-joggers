import { AmplifyService, AmplifyModules } from 'aws-amplify-angular';
import { CommonModule } from '@angular/common';
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { RouterModule } from '@angular/router';

import Auth from '@aws-amplify/auth';
import Interactions from '@aws-amplify/interactions';
import Storage from '@aws-amplify/storage';

import { AuthenticationBarComponent } from './components/authentication-bar/authentication-bar.component';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { TokenInterceptor } from './interceptors/token.interceptor';
import { AuthModule } from './auth/auth.module';

@NgModule({
  imports: [
    CommonModule,
    RouterModule,
    SharedComponentsModule,
    AuthModule
  ],
  declarations: [ AuthenticationBarComponent ],
  exports: [
      AuthenticationBarComponent
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
    },
    {
      provide: HTTP_INTERCEPTORS,
      useClass: TokenInterceptor,
      multi: true,
    }
  ],
})
export class AuthenticationModule {}
