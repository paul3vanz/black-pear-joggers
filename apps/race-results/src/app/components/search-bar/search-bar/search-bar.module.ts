// Angular Imports
import { NgModule } from '@angular/core';

// This Module's Components
import { SearchBarComponent } from './search-bar.component';

@NgModule({
  declarations: [SearchBarComponent],
  exports: [SearchBarComponent],
})
export class SearchBarModule {}
