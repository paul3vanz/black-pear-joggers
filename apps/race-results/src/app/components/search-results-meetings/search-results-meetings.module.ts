import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';

import { LoaderModule } from '../loader/loader.module';
import { NoSearchResultsMeetingsModule } from '../../components/no-search-results-meetings/no-search-results-meetings.module';
import { PipesModule } from '../../pipes/pipes.module';
import { SearchResultsMeetingsComponent } from '../../components/search-results-meetings/search-results-meetings.component';

@NgModule({
  imports: [ CommonModule, LoaderModule, NoSearchResultsMeetingsModule, PipesModule ],
  declarations: [ SearchResultsMeetingsComponent ],
  exports: [ SearchResultsMeetingsComponent ],
})
export class SearchResultsMeetingsModule {}
