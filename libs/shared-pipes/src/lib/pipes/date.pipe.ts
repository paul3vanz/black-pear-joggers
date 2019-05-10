import { Pipe, PipeTransform } from '@angular/core';
import * as moment from 'moment-mini-ts';

@Pipe({
  name: 'date',
})
export class DatePipe implements PipeTransform {
  transform(value: string, pattern?: string): string {
    if (!value) {
      return value;
    }

    const formattedValue = moment(value).format(pattern);

    return formattedValue;
  }
}
