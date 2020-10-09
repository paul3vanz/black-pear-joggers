import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GenderPipe } from './pipes/gender.pipe';
import { CategoryPipe } from './pipes/category.pipe';
import { LimitPipe } from './pipes/limit.pipe';
import { FinishTimePipe } from './pipes/finish-time.pipe';
import { PacePipe } from './pipes/pace.pipe';
import { DatePipe } from './pipes/date.pipe';
import { RaceNamePipe } from './pipes/race-name.pipe';

@NgModule({
  imports: [CommonModule],
  declarations: [
    GenderPipe,
    CategoryPipe,
    LimitPipe,
    FinishTimePipe,
    PacePipe,
    DatePipe,
    RaceNamePipe
  ],
  providers: [PacePipe],
  exports: [
    GenderPipe,
    CategoryPipe,
    LimitPipe,
    FinishTimePipe,
    PacePipe,
    DatePipe,
    RaceNamePipe
  ]
})
export class SharedPipesModule {}
