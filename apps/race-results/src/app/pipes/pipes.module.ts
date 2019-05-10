import { NgModule } from '@angular/core';

import { DatePipe } from './date.pipe';
import { EventNamePipe } from './event-name.pipe';
import { FormatAwardPipe } from './format-award.pipe';
import { FormatGenderPipe } from './format-gender.pipe';
import { NamePluralPipe } from './name-plural.pipe';
import { ReversePipe } from './reverse.pipe';

@NgModule({
  declarations: [
    DatePipe,
    EventNamePipe,
    FormatAwardPipe,
    FormatGenderPipe,
    NamePluralPipe,
    ReversePipe,
  ],
  exports: [
    DatePipe,
    EventNamePipe,
    FormatAwardPipe,
    FormatGenderPipe,
    NamePluralPipe,
    ReversePipe,
  ],
})
export class PipesModule {}
