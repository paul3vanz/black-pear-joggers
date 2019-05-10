import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MeetingPageComponent } from '../../containers/meeting-page/meeting-page.component';
import { PipesModule } from '../../pipes/pipes.module';
import { RouterModule } from '@angular/router';

@NgModule({
  imports: [ CommonModule, PipesModule, RouterModule ],
  declarations: [ MeetingPageComponent ],
  exports: [ MeetingPageComponent ],
})
export class MeetingPageModule {}
