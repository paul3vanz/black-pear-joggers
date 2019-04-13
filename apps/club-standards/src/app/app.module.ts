import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { NxModule } from '@nrwl/nx';

import { AppComponent } from './app.component';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';
import { HttpClientModule } from '@angular/common/http';

@NgModule({
  declarations: [ AppComponent ],
  imports: [ BrowserModule, HttpClientModule, NxModule.forRoot(), SharedComponentsModule ],
  providers: [],
  bootstrap: [ AppComponent ],
})
export class AppModule {}
