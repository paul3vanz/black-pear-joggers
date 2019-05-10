import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AthletePageComponent } from '../../containers/athlete-page/athlete-page.component';
import { AthleteDetailsModule } from '../../components/athlete-details/athlete-details.module';
import { AthleteStandardsModule } from '../../components/athlete-standards/athlete-standards.module';
import { AthleteResultsModule } from '../../components/athlete-results/athlete-results.module';

@NgModule({
  imports: [ CommonModule, AthleteDetailsModule, AthleteResultsModule, AthleteStandardsModule ],
  declarations: [ AthletePageComponent ],
  exports: [ AthletePageComponent ],
})
export class AthletePageModule {}
