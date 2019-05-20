import { NgModule } from '@angular/core';

import { EventNamePipe } from './event-name.pipe';
import { FormatAwardPipe } from './format-award.pipe';
import { NamePluralPipe } from './name-plural.pipe';
import { ReversePipe } from './reverse.pipe';

@NgModule({
  declarations: [ EventNamePipe, FormatAwardPipe, NamePluralPipe, ReversePipe ],
  exports: [ EventNamePipe, FormatAwardPipe, NamePluralPipe, ReversePipe ],
})
export class PipesModule {}
