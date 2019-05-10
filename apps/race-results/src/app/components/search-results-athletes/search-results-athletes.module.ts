import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PipesModule } from '../../pipes/pipes.module';
import { SearchResultsAthletesComponent } from './search-results-athletes.component';
import { LoaderModule } from '../loader/loader.module';

@NgModule({
  imports: [
    CommonModule,
    LoaderModule,
    PipesModule,
  ],
  declarations: [ SearchResultsAthletesComponent ],
  exports: [ SearchResultsAthletesComponent ],
})
export class SearchResultsAthletesModule {}
