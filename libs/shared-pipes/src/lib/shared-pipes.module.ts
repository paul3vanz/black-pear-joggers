import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GenderPipe } from './pipes/gender.pipe';
import { CategoryPipe } from './pipes/category.pipe';
import { LimitPipe } from './pipes/limit.pipe';
import { FinishTimePipe } from './finish-time.pipe';

@NgModule({
  imports: [ CommonModule ],
  declarations: [ GenderPipe, CategoryPipe, LimitPipe, FinishTimePipe ],
  exports: [ GenderPipe, CategoryPipe, LimitPipe, FinishTimePipe ],
})
export class SharedPipesModule {}
