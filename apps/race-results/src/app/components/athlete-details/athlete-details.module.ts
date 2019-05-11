import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AthleteDetailsComponent } from './athlete-details.component';
import { PipesModule } from './../pipes/pipes.module';

@NgModule({
    imports: [
        CommonModule,
        PipesModule,
    ],
    declarations: [
        AthleteDetailsComponent,
    ],
    exports: [
        AthleteDetailsComponent,
    ],
  })
  export class AthleteDetailsModule {}
