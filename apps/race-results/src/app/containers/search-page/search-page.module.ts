import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PipesModule } from '../../pipes/pipes.module';
import { SearchBarModule } from '../../components/search-bar/search-bar/search-bar.module';
import { SearchPageComponent } from '../../containers/search-page/search-page.component';
import { SearchResultsAthletesModule } from '../../components/search-results-athletes/search-results-athletes.module';
import { SearchResultsMeetingsModule } from '../../components/search-results-meetings/search-results-meetings.module';
import { SharedComponentsModule } from '@black-pear-joggers/shared-components';

@NgModule({
  imports: [ CommonModule, PipesModule, SearchBarModule, SearchResultsAthletesModule, SearchResultsMeetingsModule, SharedComponentsModule ],
  declarations: [ SearchPageComponent ],
  exports: [ SearchPageComponent ],
})
export class SearchPageModule {}
