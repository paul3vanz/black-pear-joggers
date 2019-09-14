import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthenticationBarComponent } from './components/authentication-bar/authentication-bar.component';
import { RouterModule } from '@angular/router';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { AmplifyService, AmplifyModules } from 'aws-amplify-angular';
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { TokenInterceptor } from './interceptors/token.interceptor';
import Auth from '@aws-amplify/auth';
import Interactions from '@aws-amplify/interactions';
import Storage from '@aws-amplify/storage';
import { AuthModule } from './auth/auth.module';

@NgModule({
  imports: [
    CommonModule,
    RouterModule,
    SharedComponentsModule,
    AuthModule
  ],
  declarations: [ AuthenticationBarComponent ],
  exports: [ AuthenticationBarComponent ],
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
