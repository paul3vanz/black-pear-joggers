import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GenderPipe } from './pipes/gender.pipe';
import { CategoryPipe } from './pipes/category.pipe';
import { LimitPipe } from './pipes/limit.pipe';
import { FinishTimePipe } from './finish-time.pipe';
import { PacePipe } from './pipes/pace.pipe';

@NgModule({
  imports: [ CommonModule ],
  declarations: [ GenderPipe, CategoryPipe, LimitPipe, FinishTimePipe, PacePipe ],
  exports: [ GenderPipe, CategoryPipe, LimitPipe, FinishTimePipe, PacePipe ],
})
export class SharedPipesModule {}
