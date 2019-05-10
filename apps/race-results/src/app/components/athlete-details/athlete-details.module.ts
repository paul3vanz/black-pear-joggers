import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AthleteDetailsComponent } from './athlete-details.component';
import { PipesModule } from '../../pipes/pipes.module';
import { PersonalBestModule } from '../personal-best-panel/personal-best-panel.module';

@NgModule({
    imports: [
        CommonModule,
        PersonalBestModule,
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
