import { CommonModule } from '@angular/common';
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { RouterModule } from '@angular/router';

import { EffectsModule } from '@ngrx/effects';
import { StoreModule } from '@ngrx/store';

import { Auth } from '@aws-amplify/auth';
import { Interactions } from '@aws-amplify/interactions';
import { Storage } from '@aws-amplify/storage';

import { AuthEffects } from './state/effects/auth.effects';
import { AuthenticationBarComponent } from './components/authentication-bar/authentication-bar.component';
import { AuthModule } from './auth/auth.module';
import { authReducer } from './state/reducers/auth.reducer';
import { AuthService } from './services/auth.service';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { TokenInterceptor } from './interceptors/token.interceptor';

import { AmplifyUIAngularModule } from '@aws-amplify/ui-angular';
import Amplify from '@aws-amplify/core';
import awsconfig from '../../../../src/aws-exports';

Amplify.configure(awsconfig);

@NgModule({
  imports: [
    CommonModule,
    RouterModule,
    SharedComponentsModule,
    AuthModule,
    StoreModule.forRoot({
      auth: authReducer.reducer,
    }),
    EffectsModule.forFeature([AuthEffects]),
  ],
  declarations: [AuthenticationBarComponent],
  exports: [AuthenticationBarComponent],
  providers: [
    AuthService,
    {
      provide: HTTP_INTERCEPTORS,
      useClass: TokenInterceptor,
      multi: true,
    },
  ],
})
export class AuthenticationModule {}
