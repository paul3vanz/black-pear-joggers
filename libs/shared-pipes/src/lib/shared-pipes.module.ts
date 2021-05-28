import { CategoryPipe } from './pipes/category.pipe';
import { CommonModule } from '@angular/common';
import { DatePipe } from './pipes/date.pipe';
import { FinishTimePipe } from './pipes/finish-time.pipe';
import { FormatAwardPipe } from './pipes/format-award.pipe';
import { GenderPipe } from './pipes/gender.pipe';
import { LimitPipe } from './pipes/limit.pipe';
import { NgModule } from '@angular/core';
import { PacePipe } from './pipes/pace.pipe';
import { RaceNamePipe } from './pipes/race-name.pipe';

@NgModule({
  imports: [CommonModule],
  declarations: [GenderPipe, FormatAwardPipe, CategoryPipe, LimitPipe, FinishTimePipe, PacePipe, DatePipe, RaceNamePipe],
  providers: [PacePipe],
  exports: [GenderPipe, FormatAwardPipe, CategoryPipe, LimitPipe, FinishTimePipe, PacePipe, DatePipe, RaceNamePipe],
})
export class SharedPipesModule {}
