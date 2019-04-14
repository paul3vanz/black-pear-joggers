import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgxPaginationModule } from 'ngx-pagination';
import { ResultsTableComponent } from './results-table.component';
import { DatePipe } from 'src/app/pipes/date.pipe';
import { GenderPipe } from 'src/app/pipes/gender.pipe';

@NgModule({
  imports: [CommonModule, NgxPaginationModule],
  declarations: [DatePipe, GenderPipe, ResultsTableComponent],
  exports: [ResultsTableComponent]
})
export class ResultsTableModule {}
