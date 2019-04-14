import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GenderPipe } from './gender.pipe';
import { DatePipe } from './date.pipe';
import { CategoryPipe } from './category.pipe';

@NgModule({
  imports: [CommonModule],
  declarations: [GenderPipe, DatePipe, CategoryPipe]
})
export class PipesModule {}
