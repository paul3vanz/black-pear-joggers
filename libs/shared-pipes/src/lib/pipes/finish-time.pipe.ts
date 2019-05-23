import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'finishTime',
})
export class FinishTimePipe implements PipeTransform {
  transform(timeInSeconds: number): string {
    const dateString = new Date(timeInSeconds * 1000).toISOString(); // 2011-10-05T14:48:00.000Z

    if (!timeInSeconds) return '';
    if (timeInSeconds < 600) return dateString.substr(15, 4); // e.g. 9:23
    if (timeInSeconds < 3600) return dateString.substr(14, 5); // e.g. 43:52
    if (timeInSeconds < 36000) return dateString.substr(12, 7); // e.g. 1:58:22

    return dateString.substr(11, 8); // e.g. 10:48:03
  }
}
