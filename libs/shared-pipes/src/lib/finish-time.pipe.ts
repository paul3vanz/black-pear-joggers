import { Pipe, PipeTransform } from '@angular/core';
import * as moment from 'moment-mini-ts';

@Pipe({
  name: 'finishTime',
})
export class FinishTimePipe implements PipeTransform {
  transform(timeInSeconds: number): string {
    const dateString = new Date(timeInSeconds * 1000).toISOString();

    if (!timeInSeconds) return '';
    if (timeInSeconds < 600) return dateString.substr(15, 4);
    if (timeInSeconds < 3600) return dateString.substr(14, 5);
    if (timeInSeconds < 36000) return dateString.substr(13, 6);
    return dateString.substr(11, 8);
  }
}
