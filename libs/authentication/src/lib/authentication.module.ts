import { CommonModule } from '@angular/common';
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { RouterModule } from '@angular/router';

import { EffectsModule } from '@ngrx/effects';
import { StoreModule } from '@ngrx/store';

import { AuthEffects } from './state/effects/auth.effects';
import { AuthenticationBarComponent } from './components/authentication-bar/authentication-bar.component';
import { AuthModule } from './auth/auth.module';
import { authReducer } from './state/reducers/auth.reducer';
import { AuthService } from './services/auth.service';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { TokenInterceptor } from './interceptors/token.interceptor';

import Amplify from '@aws-amplify/core';
import awsconfig from '../../../../src/aws-exports';
import { AmplifyUIAngularModule } from '@aws-amplify/ui-angular';

Amplify.configure(awsconfig);

@NgModule({
  imports: [
    CommonModule,
    RouterModule,
    SharedComponentsModule,
    AmplifyUIAngularModule,
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
