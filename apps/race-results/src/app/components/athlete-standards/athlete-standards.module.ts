import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AthleteStandardsComponent } from './athlete-standards.component';
import { PipesModule } from '../../pipes/pipes.module';

@NgModule({
    imports: [
        CommonModule,
        PipesModule,
    ],
    declarations: [
        AthleteStandardsComponent,
    ],
    exports: [
        AthleteStandardsComponent,
    ],
  })
  export class AthleteStandardsModule {}
