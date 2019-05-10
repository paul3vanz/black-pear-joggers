import { Pipe, PipeTransform } from '@angular/core';

import * as moment from 'moment-mini-ts';

@Pipe({
  name: 'date',
})
export class DatePipe implements PipeTransform {
  transform(value: string, pattern?: string): string {
    return !value ? value : moment(value).format(pattern);
  }
}
