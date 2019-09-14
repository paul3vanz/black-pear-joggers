import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AmplifyAngularModule } from 'aws-amplify-angular';

import { AppComponent } from './app.component';
import { NxModule } from '@nrwl/nx';
import { RouterModule } from '@angular/router';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { HttpClientModule } from '@angular/common/http';
// import { AuthService } from './services/auth.service';
import { StoreModule } from '@ngrx/store';
import { EffectsModule } from '@ngrx/effects';
import { StoreDevtoolsModule } from '@ngrx/store-devtools';
import { environment } from '../environments/environment';
// import { AUTH_FEATURE_KEY } from './state/reducers/auth.reducer';

import * as fromAuth from 'libs/authentication/src/lib/state/reducers/auth.reducer';
import { AuthenticationModule } from '@black-pear-joggers/authentication';
import { MagicMileModule } from './magic-mile/magic-mile.module';
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
          redirectTo: 'club-standards',
          pathMatch: 'full',
        },
        {
          path: 'club-standards',
          loadChildren: () => import('./club-standards/club-standards.module').then(m => m.ClubStandardsModule),
        },
        {
          path: 'magic-mile',
          loadChildren: () => import('./magic-mile/magic-mile.module').then(m => m.MagicMileModule),
        },
        {
          path: 'auth',
          loadChildren: () => import('libs/authentication/src/lib/auth/auth.module').then(m => m.AuthModule),
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
    AuthenticationModule,
    SharedPipesModule,
    MagicMileModule,
  ],
  bootstrap: [ AppComponent ],
})
export class AppModule {}
