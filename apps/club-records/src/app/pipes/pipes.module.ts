import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GenderPipe } from './gender.pipe';
import { DatePipe } from './date.pipe';
import { CategoryPipe } from './category.pipe';
import { FilterCategoryPipe } from './filter-category.pipe';
import { PacePipe } from './pace.pipe';

@NgModule({
  imports: [ CommonModule ],
  declarations: [ GenderPipe, DatePipe, CategoryPipe, FilterCategoryPipe, PacePipe ],
  exports: [ GenderPipe, DatePipe, CategoryPipe, FilterCategoryPipe, PacePipe ],
})
export class PipesModule {}
