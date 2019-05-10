import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AthleteResultsComponent } from './athlete-results.component';
import { PipesModule } from '../../pipes/pipes.module';

@NgModule({
  imports: [ CommonModule, PipesModule ],
  declarations: [ AthleteResultsComponent ],
  exports: [ AthleteResultsComponent ],
})
export class AthleteResultsModule {}
