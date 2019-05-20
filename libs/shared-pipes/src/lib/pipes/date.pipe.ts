import { Pipe, PipeTransform } from '@angular/core';
import * as moment from 'moment-mini-ts';

@Pipe({
  name: 'date',
})
export class DatePipe implements PipeTransform {
  transform(dateString: string, pattern?: string): string {
    if (!dateString) {
      return dateString;
    }

    const dateAsMoment = moment(dateString);

    if (pattern === 'fromNow') {
      return dateAsMoment.fromNow();
    }

    return dateAsMoment.format(pattern);
  }
}
