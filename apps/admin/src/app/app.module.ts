import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AppComponent } from './app.component';
import { NxModule } from '@nrwl/nx';
import { RouterModule } from '@angular/router';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { SharedPipesModule } from '@black-pear-joggers/shared-pipes';
import { HttpClientModule } from '@angular/common/http';

@NgModule({
  declarations: [ AppComponent ],
  imports: [
    BrowserModule,
    NxModule.forRoot(),
    RouterModule.forRoot(
      [
        {
          path: '',
          redirectTo: '/club-standards',
          pathMatch: 'full',
        },
        {
          path: 'club-standards',
          loadChildren: () => import('./club-standards/club-standards.module').then(m => m.ClubStandardsModule),
        },
      ],
      { initialNavigation: 'enabled', anchorScrolling: 'enabled', useHash: true }
    ),
    HttpClientModule,

    SharedComponentsModule,
    SharedPipesModule,
  ],
  providers: [],
  bootstrap: [ AppComponent ],
})
export class AppModule {}
