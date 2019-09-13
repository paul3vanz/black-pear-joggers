import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AmplifyAngularModule, AmplifyService, AmplifyModules } from 'aws-amplify-angular';
import Auth from '@aws-amplify/auth';
import Interactions from '@aws-amplify/interactions';
import Storage from '@aws-amplify/storage';

import { AppComponent } from './app.component';
import { NxModule } from '@nrwl/nx';
import { RouterModule } from '@angular/router';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
// import { AuthService } from './services/auth.service';
import { StoreModule } from '@ngrx/store';
import { EffectsModule } from '@ngrx/effects';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { environment } from '../environments/environment';
// import { AUTH_FEATURE_KEY } from './state/reducers/auth.reducer';
import { TokenInterceptor } from './interceptors/token.interceptor';

import * as fromAuth from './state/reducers/auth.reducer';
// import { AuthEffects } from './state/effects/auth.effects';

@NgModule({
  declarations: [ AppComponent ],
  imports: [
    BrowserModule,
    NxModule.forRoot(),
    RouterModule.forRoot(
      [
        {
          path: '',
          redirectTo: '/auth',
          pathMatch: 'full',
        },
        {
          path: 'club-standards',
          loadChildren: () => import('./club-standards/club-standards.module').then(m => m.ClubStandardsModule),
        },
        {
          path: 'auth',
          loadChildren: () => import('./auth/auth.module').then(m => m.AuthModule),
        }
      ],
      { initialNavigation: 'enabled', anchorScrolling: 'enabled', useHash: true }
    ),
    StoreModule.forRoot({
      auth: fromAuth.reducer
    }),
    EffectsModule.forRoot([
      // AuthEffects
    ]),
    StoreDevtoolsModule.instrument({
      maxAge: 25,
      logOnly: environment.production,
    }),
    HttpClientModule,
    AmplifyAngularModule,
    SharedComponentsModule,
    SharedPipesModule,
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
  bootstrap: [ AppComponent ],
})
export class AppModule {}
