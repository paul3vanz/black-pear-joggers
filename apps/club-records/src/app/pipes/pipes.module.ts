import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GenderPipe } from './gender.pipe';
import { DatePipe } from './date.pipe';
import { CategoryPipe } from './category.pipe';
import { FilterCategoryPipe } from './filter-category.pipe';

@NgModule({
  imports: [CommonModule],
  declarations: [GenderPipe, DatePipe, CategoryPipe, FilterCategoryPipe],
  exports: [GenderPipe, DatePipe, CategoryPipe, FilterCategoryPipe]
})
export class PipesModule {}
