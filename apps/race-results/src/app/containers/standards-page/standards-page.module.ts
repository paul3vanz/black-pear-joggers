import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PipesModule } from '../../pipes/pipes.module';
import { StandardsPageComponent } from '../../containers/standards-page/standards-page.component';
import { AthleteStandardsModule } from '../../components/athlete-standards/athlete-standards.module';

@NgModule({
  imports: [ AthleteStandardsModule, CommonModule, PipesModule ],
  declarations: [ StandardsPageComponent ],
  exports: [ StandardsPageComponent ],
})
export class StandardsPageModule {}
